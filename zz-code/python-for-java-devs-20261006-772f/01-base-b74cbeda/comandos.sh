# Comandos Bash de la sesión b74cbeda-4ebe-41e8-a4a9-572ad0a26258, en orden. Una bitácora, no un script: no se corre entera.

# --- 2026-09-13T00:54:05 · List course files
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && find . -type f | head -50 && echo "---SIZES---" && ls -la prompts/

# --- 2026-09-13T00:54:08 · Read prompts README
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts && cat README.md

# --- 2026-09-13T00:55:58 · Read scope document
cat alcance-del-proyecto.md

# --- 2026-09-13T00:56:03 · Outline of phases proposal
grep -n '^#\{1,3\} ' propuesta-fases-y-alcance.md

# --- 2026-09-13T00:56:07 · Read sections 1-4
sed -n '1,175p' propuesta-fases-y-alcance.md

# --- 2026-09-13T00:56:09 · Read sections 6-11
sed -n '797,960p' propuesta-fases-y-alcance.md

# --- 2026-09-13T00:56:12 · Read templates and phase prompts intro
cat plantillas-de-capitulo.md; echo "=====PROMPTS DE FASE ===="; sed -n '1,200p' prompts-de-fase.md

# --- 2026-09-13T00:56:16 · Read remaining phase prompts
sed -n '200,700p' prompts-de-fase.md

# --- 2026-09-13T00:56:28 · Check sibling course size and root doc prompts
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs 2>/dev/null && ls && echo "--- tamaños ---" && ls -la *.md 2>/dev/null | head -30; echo "=== root prompts doc ==="; cat /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts/prompts-documentos-raiz.md

# --- 2026-09-13T00:57:02 · Return to course dir and outline style guide
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && pwd && grep -n '^#\{1,3\} ' prompts/guia-de-estilo-y-convenciones.md

# --- 2026-09-13T00:58:50 · Read style guide part 1
sed -n '1,240p' prompts/guia-de-estilo-y-convenciones.md

# --- 2026-09-13T00:58:57 · Query PyPI for current versions
for p in uv ruff mypy pytest fastapi pydantic sqlalchemy alembic django httpx hypothesis uvicorn; do v=$(curl -s "https://pypi.org/pypi/$p/json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['info']['version'], d['urls'][0]['upload_time'][:10] if d['urls'] else '')" 2>/dev/null); echo "$p -> $v"; done

# --- 2026-09-13T00:59:19 · Query more package versions
for p in pip pip-tools pyright psycopg celery arq redis prometheus-client opentelemetry-sdk structlog typer rich pyinstaller pytest-cov; do v=$(curl -s "https://pypi.org/pypi/$p/json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['info']['version'], d['urls'][0]['upload_time'][:10] if d['urls'] else '')" 2>/dev/null); echo "$p -> $v"; done; echo "--- miniforge ---"; curl -s https://api.github.com/repos/conda-forge/miniforge/releases/latest | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['tag_name'], d['published_at'][:10])"

# --- 2026-09-13T00:59:33 · Show section 9 with line numbers
grep -n "" prompts/alcance-del-proyecto.md | sed -n '/## 9. Restricciones/,/## 10./p'

# --- 2026-09-13T00:59:50 · Pin exact versions in scope doc
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

# --- 2026-09-13T00:59:55 · Read style guide part 2
sed -n '240,600p' prompts/guia-de-estilo-y-convenciones.md

# --- 2026-09-13T01:00:00 · Outline of Aurea story
grep -n '^#\{1,3\} ' prompts/historia-propuesta-2-aurea.md | head -60

# --- 2026-09-13T01:00:03 · Read Aurea story sections 1-2
sed -n '1,250p' prompts/historia-propuesta-2-aurea.md

# --- 2026-09-13T01:00:06 · Read sections 4-6 of story
sed -n '246,420p' prompts/historia-propuesta-2-aurea.md

# --- 2026-09-13T01:02:04 · Check miniproject format section 4.8
grep -n '^#\{1,4\} ' prompts/formato-de-miniproyectos.md && sed -n '/4.8/,/^## 5/p' prompts/formato-de-miniproyectos.md | head -40

# --- 2026-09-13T01:03:25 · Check file sizes and line lengths
ls -la *.md && echo "--- líneas > 100 chars (deben ser 0 salvo tablas) ---" && awk 'length>100 && $0 !~ /^\|/ {print FILENAME": "FNR}' *.md | head

# --- 2026-09-13T01:03:29 · Inspect long lines
sed -n '150p;156p;172p' 0-ESTRUCTURA-CURSO.md; sed -n '56p' 00-convencion-de-git-y-tags.md

# --- 2026-09-13T01:07:16 · Read detailed scope of phases 00-02
sed -n '173,300p' prompts/propuesta-fases-y-alcance.md

# --- 2026-09-13T01:07:19 · Read measurement format
cat prompts/formato-de-mediciones.md

# --- 2026-09-13T01:07:22 · Read miniproject format
sed -n '12,200p' prompts/formato-de-miniproyectos.md

# --- 2026-09-13T01:07:53 · Check PyCharm version and VS Code extension IDs
curl -s "https://data.services.jetbrains.com/products/releases?code=PCP&latest=true&type=release" | python3 -c "import sys,json;d=json.load(sys.stdin);r=d['PCP'][0];print(r['version'], r['date'])"; echo "--- vscode python ext ---"; for ext in ms-python.python ms-python.vscode-pylance ms-python.debugpy charliermarsh.ruff; do echo -n "$ext: "; curl -s -X POST "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery" -H "Content-Type: application/json" -H "Accept: application/json;api-version=7.2-preview.1" -d "{\"filters\":[{\"criteria\":[{\"filterType\":7,\"value\":\"$ext\"}]}],\"flags\":914}" | python3 -c "import sys,json
d=json.load(sys.stdin)
try:
    e=d['results'][0]['extensions'][0]; print(e['displayName'],'|',e['publisher']['displayName'],'|',e['versions'][0]['version'])
except Exception as ex: print('n/a')"; done

# --- 2026-09-13T01:08:31 · Check local toolchain
which -a python3 python3.14 java javac 2>/dev/null; echo "---"; python3 -VV; java -version 2>&1 | head -3; sw_vers 2>/dev/null | head -2; uname -m; sysctl -n hw.ncpu 2>/dev/null

# --- 2026-09-13T01:08:39 · Prepare cold start benchmark
/opt/homebrew/bin/python3.14 -VV; cd /tmp/claude-501 && mkdir -p coldstart && cd coldstart && cat > Hello.java <<'EOF'
public class Hello { public static void main(String[] a){ System.out.print(""); } }
EOF
javac Hello.java && echo compiled

# --- 2026-09-13T01:08:49 · Run cold start benchmark
cd /tmp/claude-501/coldstart && cat > bench.py <<'EOF'
import subprocess, time, statistics, sys

def bench(cmd, reps=30):
    for _ in range(3):
        subprocess.run(cmd, capture_output=True)
    xs = []
    for _ in range(reps):
        t0 = time.perf_counter()
        subprocess.run(cmd, capture_output=True)
        xs.append((time.perf_counter() - t0) * 1000)
    xs.sort()
    return statistics.median(xs), xs[int(len(xs)*0.95)-1], min(xs)

casos = {
    "python -c pass": ["/opt/homebrew/bin/python3.14", "-c", "pass"],
    "python -S -c pass": ["/opt/homebrew/bin/python3.14", "-S", "-c", "pass"],
    "python -c import json,csv,pathlib": ["/opt/homebrew/bin/python3.14", "-c", "import json,csv,pathlib,argparse"],
    "java Hello": ["java", "-cp", ".", "Hello"],
    "java -XX:TieredStopAtLevel=1 -Xshare:auto Hello": ["java", "-XX:TieredStopAtLevel=1", "-Xshare:auto", "-cp", ".", "Hello"],
}
for n, c in casos.items():
    med, p95, mn = bench(c)
    print(f"{n:50s} mediana {med:7.1f} ms   p95 {p95:7.1f} ms   min {mn:7.1f} ms")
EOF
/opt/homebrew/bin/python3.14 bench.py

# --- 2026-09-13T01:15:29 · Run the reference solution
cd /tmp/claude-501 && python3 - <<'EOF'
import re, pathlib
doc = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/00-ambiente-editores-y-ecosistema.md").read_text()
blocks = re.findall(r"```python\n(.*?)```", doc, re.S)
code = max(blocks, key=len)
pathlib.Path("diagnostico.py").write_text(code)
print("líneas:", len(code.splitlines()))
EOF
/opt/homebrew/bin/python3.14 diagnostico.py; echo "código de salida: $?"

# --- 2026-09-13T01:15:37 · Test scenario 3 detection
cd /tmp/claude-501 && /opt/homebrew/bin/python3.14 -m venv .venv-test -q && VIRTUAL_ENV=/tmp/claude-501/.venv-test PATH=/tmp/claude-501/.venv-test/bin:$PATH /usr/bin/python3 diagnostico.py | tail -8; echo "salida: $?"; ./.venv-test/bin/python diagnostico.py | sed -n '/Entorno/,/^$/p'

# --- 2026-09-13T01:15:42 · Test venv scenarios
cd /tmp/claude-501 && /opt/homebrew/bin/python3.14 -m venv .venv-test && echo "--- escenario 3 (venv activo, otro intérprete) ---" && VIRTUAL_ENV=/tmp/claude-501/.venv-test /usr/bin/python3 diagnostico.py | sed -n '/Avisos/,$p'; echo "--- escenario 1 (venv, sin activar) ---"; /tmp/claude-501/.venv-test/bin/python diagnostico.py | sed -n '/Entorno virtual/,/^$/p'

# --- 2026-09-13T01:15:59 · Fix and retest on old interpreter
cd /tmp/claude-501 && sed -i '' 's/^import os$/from __future__ import annotations\n\nimport os/' diagnostico.py && head -12 diagnostico.py && echo "=== escenario 3 con python3 del sistema ===" && /usr/bin/python3 -V && VIRTUAL_ENV=/tmp/claude-501/.venv-test /usr/bin/python3 diagnostico.py | sed -n '/Avisos/,$p'

# --- 2026-09-13T01:16:23 · Apply fixes found by running the code
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p = "00-ambiente-editores-y-ecosistema.md"
s = io.open(p, encoding="utf-8").read()

# 1. La solución de referencia: from __future__ import annotations
old = '''Sale con 0 si no encontró inconsistencias, con 1 si encontró alguna.
"""

import os'''
new = '''Sale con 0 si no encontró inconsistencias, con 1 si encontró alguna.
"""

# Esta línea es la que permite que el diagnóstico corra en el Python viejo de la máquina
# ajena: sin ella, una anotación como `dict[str, str] | None` se evalúa al importar el
# módulo y revienta en cualquier intérprete anterior a 3.10. Con ella, las anotaciones
# quedan como texto y nadie las mira en tiempo de ejecución.
from __future__ import annotations

import os'''
assert old in s
s = s.replace(old, new)

# 2. Escenario 4 en datos de entrada
old2 = """3. Ejecutado con el entorno activo pero **invocando explícitamente otro intérprete**
   (`/usr/bin/python3 diagnostico.py` con el `.venv` activo). Este es el caso sucio, es el que
   produce los errores más confusos de la vida real, y un diagnóstico que no lo detecta no
   sirve."""
new2 = """3. Ejecutado con el entorno activo pero **invocando explícitamente otro intérprete**
   (`/usr/bin/python3 diagnostico.py` con el `.venv` activo). Este es el caso sucio, es el que
   produce los errores más confusos de la vida real, y un diagnóstico que no lo detecta no
   sirve.
4. Ejecutado con **un intérprete viejo** — el `python3` del sistema, que en muchos macOS todavía
   es un 3.9. Es el escenario real del encargo: la máquina de Patricia es justamente la que no
   tiene 3.14, y una herramienta de diagnóstico que exige la versión que viene a diagnosticar no
   diagnostica nada."""
assert old2 in s
s = s.replace(old2, new2)

# 3. Criterio de aceptación
old3 = """- [ ] Corre con `python diagnostico.py` en las tres plataformas sin modificarse, y sin importar
      nada que no venga en la biblioteca estándar."""
new3 = """- [ ] Corre con `python diagnostico.py` en las tres plataformas sin modificarse, y sin importar
      nada que no venga en la biblioteca estándar.
- [ ] **Corre también en un intérprete viejo** (3.9 en adelante) sin reventar al arrancar. Es el
      único código de todo el curso con ese requisito, y el encargo es la razón."""
assert old3 in s
s = s.replace(old3, new3)

# 4. La trampa: añadir la tercera
old4 = """Y hay una segunda, más sutil: ejecutar cada candidato para preguntarle su versión significa
**lanzar procesos**, y si uno se cuelga, tu herramienta se cuelga con él en la máquina de
Patricia un viernes a las seis."""
new4 = """Y hay una segunda, más sutil: ejecutar cada candidato para preguntarle su versión significa
**lanzar procesos**, y si uno se cuelga, tu herramienta se cuelga con él en la máquina de
Patricia un viernes a las seis.

Y una tercera, que es la más irónica de las tres: vas a escribir el diagnóstico con la sintaxis
de 3.14 porque es la que tienes delante, y va a reventar **en el arranque** —antes de imprimir
una sola línea útil— en la máquina vieja que venía a diagnosticar. El mensaje que reciba
Patricia va a ser un `TypeError` sobre un operador `|`. Arreglarlo es una línea; encontrarla es
el ejercicio."""
assert old4 in s
s = s.replace(old4, new4)

# 5. Ejercicio 7
old5 = """7. `python -c "import sys; print(sys.path)"` dentro y fuera del entorno virtual. Explica qué
   entradas cambian, cuáles no, y por qué la primera suele ser una cadena vacía."""
new5 = """7. `python -c "import sys; print(sys.path)"` dentro y fuera del entorno virtual. Explica qué
   entradas cambian y cuáles no. Después repite con un archivo (`python ver_path.py`) y explica
   por qué la primera entrada es distinta en los dos casos."""
assert old5 in s
s = s.replace(old5, new5)

io.open(p, "w", encoding="utf-8").write(s)
print("ok")
PYEOF

# --- 2026-09-13T01:16:34 · Add third trap explanation
python3 - <<'PYEOF'
import io
p = "00-ambiente-editores-y-ecosistema.md"
s = io.open(p, encoding="utf-8").read()
old = """05 convierte en tema: **lanzar un proceso hijo es delegar el control, y siempre hay que poder
recuperarlo.**"""
new = """05 convierte en tema: **lanzar un proceso hijo es delegar el control, y siempre hay que poder
recuperarlo.**

Y la tercera trampa se paga con `from __future__ import annotations` en la primera línea. Sin
ella, el archivo no llega a ejecutarse en un intérprete anterior a 3.10: las anotaciones de las
firmas se evalúan al importar el módulo, `dict[str, str] | None` no existe allí, y el usuario
recibe un `TypeError` en vez de un diagnóstico. Probado: con esa línea, el mismo archivo corre
en 3.9 y detecta correctamente el escenario 3. Es el único sitio del curso donde se escribe
código defensivo para atrás, y se justifica porque la herramienta existe para correr en la
máquina que no controlas."""
assert old in s
io.open(p, "w", encoding="utf-8").write(s.replace(old, new))
print("ok")
PYEOF
wc -c 00-ambiente-editores-y-ecosistema.md

# --- 2026-09-13T01:16:52 · Measure membership list vs set vs dict
cd /tmp/claude-501 && cat > memb.py <<'EOF'
import random, statistics, time

random.seed(2026)
def doc():  # cédulas colombianas plausibles
    return str(random.randint(10_000_000, 1_299_999_999))

ids = [doc() for _ in range(2800)]
as_list, as_set, as_dict = ids, set(ids), {d: i for i, d in enumerate(ids)}

# mitad presentes, mitad ausentes: el caso realista de una consolidación
queries = ids[:1400] + [doc() for _ in range(1400)]
random.shuffle(queries)

def bench(container, reps=15):
    xs = []
    for _ in range(reps):
        t0 = time.perf_counter()
        n = sum(1 for q in queries if q in container)
        xs.append((time.perf_counter() - t0) * 1000)
    xs.sort()
    return statistics.median(xs), xs[int(len(xs)*0.95)-1], n

for name, c in [("list", as_list), ("set", as_set), ("dict", as_dict)]:
    med, p95, n = bench(c)
    print(f"{name:6s} mediana {med:8.3f} ms  p95 {p95:8.3f} ms  (encontrados {n})")

# comparaciones promedio en la lista
tot = 0
for q in queries:
    for i, v in enumerate(as_list, 1):
        if v == q:
            tot += i; break
    else:
        tot += len(as_list)
print(f"\ncomparaciones promedio por consulta en list: {tot/len(queries):.0f}")
print(f"tamaño en memoria: list {as_list.__sizeof__()} B · set {as_set.__sizeof__()} B · dict {as_dict.__sizeof__()} B")
EOF
/opt/homebrew/bin/python3.14 memb.py

# --- 2026-09-13T01:17:02 · Measure crossover threshold
cd /tmp/claude-501 && cat > memb2.py <<'EOF'
import random, statistics, time
random.seed(2026)
def doc(): return str(random.randint(10_000_000, 1_299_999_999))
for n in (10, 50, 200, 1000, 2800):
    ids=[doc() for _ in range(n)]
    qs=ids[:n//2]+[doc() for _ in range(n//2)]
    def b(c):
        xs=[]
        for _ in range(21):
            t0=time.perf_counter(); sum(1 for q in qs if q in c); xs.append((time.perf_counter()-t0)*1e6)
        return statistics.median(xs)
    print(f"n={n:5d}  list {b(ids):9.1f} µs   set {b(set(ids)):9.1f} µs   ratio {b(ids)/b(set(ids)):6.1f}×")
EOF
/opt/homebrew/bin/python3.14 memb2.py

# --- 2026-09-13T01:22:23 · Run the Fase 01 CLI
cd /tmp/claude-501 && rm -rf f01 && mkdir f01 && cd f01 && python3 - <<'EOF'
import re, pathlib
doc = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/01-modelo-de-datos.md").read_text()
blocks = re.findall(r"```python\n(.*?)```", doc, re.S)
cli = [b for b in blocks if b.startswith('"""aur —')][0]
gen = [b for b in blocks if b.startswith('"""Genera')][0]
pathlib.Path("aur_cli.py").write_text(cli)
pathlib.Path("generar_datos_f01.py").write_text(gen)
pathlib.Path("data").mkdir(exist_ok=True)
pathlib.Path("data/centro-2026-03.csv").write_text(
"""documento,paciente,sede,fecha,codigo,valor
1019283746,Ana María Robledo,Centro,2026-03-04,D8010,180000
52847193,Carlos Efrén Neira,Centro,2026-03-04,D2740,890000
1019283746,Ana María Robledo,Centro,2026-03-18,D8020,95000
79541226,Luz Dary Peña,Centro,2026-03-19,D8010,180000
""", encoding="utf-8")
EOF
/opt/homebrew/bin/python3.14 aur_cli.py resumen data/centro-2026-03.csv; echo "salida=$?"; echo "--- invocación mala ---"; /opt/homebrew/bin/python3.14 aur_cli.py; echo "salida=$?"

# --- 2026-09-13T01:22:29 · Run the data generator
cd /tmp/claude-501/f01 && /opt/homebrew/bin/python3.14 generar_datos_f01.py && echo "--- muestra ---" && head -4 data/centro-2026-03.csv && wc -l data/*.csv | tail -1 && /opt/homebrew/bin/python3.14 aur_cli.py resumen data/suba-2026-03.csv | head -5

# --- 2026-09-13T01:22:45 · Seed the two hard cases in the generator
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p = "01-modelo-de-datos.md"
s = io.open(p, encoding="utf-8").read()

old = """    # 340 de ellos se atienden en una segunda sede: son los duplicados de verdad.
    shared = random.sample(people, 340)

    for branch in BRANCHES:"""

new = """    # 340 de ellos se atienden en una segunda sede: son los duplicados de verdad.
    shared = random.sample(people, 340)

    # Y los dos casos que ninguna normalización resuelve, sembrados a propósito.
    # Están aquí porque existen en Áurea, no para hacer el ejercicio más difícil.
    document, name = people[7]
    people.append((document, "Gloria Esperanza Mahecha Vargas"))  # mismo documento, otra persona
    document, name = people[11]
    swapped = document[:-2] + document[-1] + document[-2]         # dígitos cambiados al digitar
    people.append((swapped, name))                                 # misma persona, otro documento

    for branch in BRANCHES:"""
assert old in s
s = s.replace(old, new)

old2 = """        for document, name in random.sample(people, 260) + random.sample(shared, 40):"""
new2 = """        # Los dos últimos de `people` son los casos sembrados: entran siempre, para que
        # aparezcan repartidos en la red y no dependan del azar del muestreo.
        for document, name in random.sample(people, 260) + random.sample(shared, 40) + people[-2:]:"""
assert old2 in s
s = s.replace(old2, new2)

io.open(p, "w", encoding="utf-8").write(s)
print("ok")
PYEOF

# --- 2026-09-13T01:22:56 · Verify the two seeded hard cases appear
cd /tmp/claude-501/f01 && rm -rf data && python3 - <<'EOF'
import re, pathlib
doc = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/01-modelo-de-datos.md").read_text()
gen = [b for b in re.findall(r"```python\n(.*?)```", doc, re.S) if b.startswith('"""Genera')][0]
pathlib.Path("generar_datos_f01.py").write_text(gen)
EOF
/opt/homebrew/bin/python3.14 generar_datos_f01.py >/dev/null && /opt/homebrew/bin/python3.14 - <<'EOF'
import unicodedata, pathlib, collections
def strip(t): return "".join(c for c in unicodedata.normalize("NFD", t) if unicodedata.category(c)!="Mn")
def ndoc(d): return d.strip().replace(".","")
def nname(n): return strip(n).casefold().strip()
by_doc, by_name = collections.defaultdict(set), collections.defaultdict(set)
rows=0
for f in sorted(pathlib.Path("data").glob("*.csv")):
    for line in f.read_text(encoding="utf-8").splitlines()[1:]:
        if not line.strip(): continue
        d,n,*_ = line.split(","); rows+=1
        by_doc[ndoc(d)].add(nname(n)); by_name[nname(n)].add(ndoc(d))
print("filas:", rows)
print("pacientes con normalización:", len(by_doc))
print("mismo documento, nombres distintos:", [(k,v) for k,v in by_doc.items() if len(v)>1])
print("mismo nombre, documentos distintos:", [(k,v) for k,v in by_name.items() if len(v)>1])
EOF

# --- 2026-09-13T01:23:26 · Make generator names unique
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p = "01-modelo-de-datos.md"
s = io.open(p, encoding="utf-8").read()

old = '''FIRST = ["Ana María", "Carlos Efrén", "Luz Dary", "Jhon Fredy", "Diana Marcela",
         "Óscar Iván", "Yenny Paola", "Wílmer Andrés", "Sandra Milena", "José Ángel"]
LAST = ["Robledo", "Neira", "Peña", "Chaparro", "Ocampo", "Guzmán", "Rojas",
        "Buitrago", "Cárdenas", "Quintero"]'''
new = '''FIRST = ["Ana María", "Carlos Efrén", "Luz Dary", "Jhon Fredy", "Diana Marcela",
         "Óscar Iván", "Yenny Paola", "Wílmer Andrés", "Sandra Milena", "José Ángel",
         "Nubia Esther", "Édinson Alberto", "Leidy Johana", "Fabián Ricardo",
         "Martha Liliana", "Héctor Julio", "Claudia Patricia", "Freddy Alexánder",
         "Rocío del Pilar", "Gustavo Adolfo", "Mónica Andrea", "Jairo Enrique",
         "Astrid Carolina", "Néstor Fabio"]
LAST = ["Robledo", "Neira", "Peña", "Chaparro", "Ocampo", "Guzmán", "Rojas",
        "Buitrago", "Cárdenas", "Quintero", "Mahecha", "Bermúdez", "Alfonso",
        "Chacón", "Piraquive", "Urrego", "Salamanca", "Bohórquez", "Trujillo",
        "Velandia", "Camargo", "Sáenz", "Pulido", "Lozano", "Forero", "Amaya",
        "Barbosa", "Gaitán", "Rincón", "Támara"]'''
assert old in s
s = s.replace(old, new)

old2 = '''    # 2.800 pacientes reales en la red, cada uno con su documento canónico.
    people = [(str(random.randint(10_000_000, 1_299_999_999)),
               f"{random.choice(FIRST)} {random.choice(LAST)} {random.choice(LAST)}")
              for _ in range(2800)]'''
new2 = '''    # 2.800 pacientes reales en la red, cada uno con su documento canónico y su nombre.
    # Los nombres se muestrean SIN repetición del producto completo: así el único homónimo
    # de los datos es el que sembramos abajo a propósito, y la señal no se pierde entre
    # coincidencias de azar. (En los datos reales de Áurea sí hay homónimos de verdad;
    # el ejercicio 🔥 del final te pide qué cambiaría si los hubiera.)
    all_names = [f"{first} {last1} {last2}"
                 for first in FIRST for last1 in LAST for last2 in LAST if last1 != last2]
    people = [(str(random.randint(10_000_000, 1_299_999_999)), name)
              for name in random.sample(all_names, 2800)]'''
assert old2 in s
s = s.replace(old2, new2)

# El ejercicio 🔥 que la nota promete
old3 = """- Reescribe `summarize` sin bucles explícitos, usando solo comprehensions. Después decide
  honestamente cuál de las dos versiones dejarías en un archivo que va a mantener alguien que no
  eres tú."""
new3 = """- Reescribe `summarize` sin bucles explícitos, usando solo comprehensions. Después decide
  honestamente cuál de las dos versiones dejarías en un archivo que va a mantener alguien que no
  eres tú.
- El generador siembra nombres únicos para que la señal del miniproyecto se vea. En los datos
  reales de Áurea hay homónimos de verdad — dos "Jhon Fredy Rojas Buitrago" que son dos personas.
  Modifica el generador para que produzca una docena de homónimos legítimos, vuelve a correr tu
  consolidado, y escribe qué le dirías a Patricia sobre la lista de dudosos que le sale ahora."""
assert old3 in s
s = s.replace(old3, new3)

io.open(p, "w", encoding="utf-8").write(s)
print("ok")
PYEOF

# --- 2026-09-13T01:23:36 · Re-verify seeded cases are now the only ones
cd /tmp/claude-501/f01 && rm -rf data && python3 - <<'EOF'
import re, pathlib
doc = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/01-modelo-de-datos.md").read_text()
gen = [b for b in re.findall(r"```python\n(.*?)```", doc, re.S) if b.startswith('"""Genera')][0]
pathlib.Path("generar_datos_f01.py").write_text(gen)
EOF
/opt/homebrew/bin/python3.14 generar_datos_f01.py | tail -2 && /opt/homebrew/bin/python3.14 - <<'EOF'
import unicodedata, pathlib, collections
def strip(t): return "".join(c for c in unicodedata.normalize("NFD", t) if unicodedata.category(c)!="Mn")
by_doc, by_name, raw = collections.defaultdict(set), collections.defaultdict(set), set()
rows=0
for f in sorted(pathlib.Path("data").glob("*.csv")):
    for line in f.read_text(encoding="utf-8").splitlines()[1:]:
        if not line.strip(): continue
        d,n,*_ = line.split(","); rows+=1
        raw.add(d)
        nd, nn = d.strip().replace(".",""), strip(n).casefold().strip()
        by_doc[nd].add(nn); by_name[nn].add(nd)
print("filas:", rows, "| docs sin normalizar:", len(raw), "| con normalización:", len(by_doc))
print("mismo doc, nombres distintos:", [(k,v) for k,v in by_doc.items() if len(v)>1])
print("mismo nombre, docs distintos:", [(k,sorted(v)) for k,v in by_name.items() if len(v)>1])
EOF

# --- 2026-09-13T01:24:00 · Seed cases deterministically and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p = "01-modelo-de-datos.md"
s = io.open(p, encoding="utf-8").read()

old = """    # Y los dos casos que ninguna normalización resuelve, sembrados a propósito.
    # Están aquí porque existen en Áurea, no para hacer el ejercicio más difícil.
    document, name = people[7]
    people.append((document, "Gloria Esperanza Mahecha Vargas"))  # mismo documento, otra persona
    document, name = people[11]
    swapped = document[:-2] + document[-1] + document[-2]         # dígitos cambiados al digitar
    people.append((swapped, name))                                 # misma persona, otro documento

    for branch in BRANCHES:"""
new = """    # Y los dos casos que ninguna normalización resuelve, sembrados a propósito y
    # repartidos en sedes concretas para que no dependan del azar del muestreo.
    # Están aquí porque existen en Áurea, no para hacer el ejercicio más difícil.
    document_a, name_a = people[7]
    document_b, name_b = people[11]
    swapped = document_b[:-2] + document_b[-1] + document_b[-2]   # dígitos cambiados al digitar

    seeded = {
        # Mismo documento, dos personas: alguien digitó mal la cédula al admitir a Gloria.
        "Centro": [(document_a, name_a)],
        "Kennedy": [(document_a, "Gloria Esperanza Mahecha Vargas")],
        # Misma persona, dos documentos: Suba le invirtió dos dígitos.
        "Chapinero": [(document_b, name_b)],
        "Suba": [(swapped, name_b)],
    }

    for branch in BRANCHES:"""
assert old in s
s = s.replace(old, new)

old2 = """        # Los dos últimos de `people` son los casos sembrados: entran siempre, para que
        # aparezcan repartidos en la red y no dependan del azar del muestreo.
        for document, name in random.sample(people, 260) + random.sample(shared, 40) + people[-2:]:"""
new2 = """        for document, name in (random.sample(people, 260) + random.sample(shared, 40)
                               + seeded.get(branch, [])):"""
assert old2 in s
s = s.replace(old2, new2)
io.open(p, "w", encoding="utf-8").write(s)
print("ok")
PYEOF
cd /tmp/claude-501/f01 && rm -rf data && python3 -c "
import re,pathlib
doc=pathlib.Path('/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/01-modelo-de-datos.md').read_text()
gen=[b for b in re.findall(r'\`\`\`python\n(.*?)\`\`\`',doc,re.S) if b.startswith('\"\"\"Genera')][0]
pathlib.Path('generar_datos_f01.py').write_text(gen)" && /opt/homebrew/bin/python3.14 generar_datos_f01.py | tail -1 && /opt/homebrew/bin/python3.14 - <<'EOF'
import unicodedata, pathlib, collections
def strip(t): return "".join(c for c in unicodedata.normalize("NFD", t) if unicodedata.category(c)!="Mn")
by_doc, by_name, raw = collections.defaultdict(set), collections.defaultdict(set), set()
rows=0
for f in sorted(pathlib.Path("data").glob("*.csv")):
    for line in f.read_text(encoding="utf-8").splitlines()[1:]:
        if not line.strip(): continue
        d,n,*_=line.split(","); rows+=1; raw.add(d)
        nd,nn=d.strip().replace(".",""), strip(n).casefold().strip()
        by_doc[nd].add(nn); by_name[nn].add(nd)
print("filas:",rows,"| sin normalizar:",len(raw),"| normalizado:",len(by_doc))
print("mismo doc, nombres distintos:",[(k,sorted(v)) for k,v in by_doc.items() if len(v)>1])
print("mismo nombre, docs distintos:",[(k,sorted(v)) for k,v in by_name.items() if len(v)>1])
EOF

# --- 2026-09-13T01:25:10 · Add asset to src and index the contract
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && mkdir -p src/01-modelo-de-datos && cp /tmp/claude-501/f01/generar_datos_f01.py src/01-modelo-de-datos/generar_datos_f01.py && python3 - <<'PYEOF'
import io
p = "prompts/README.md"
s = io.open(p, encoding="utf-8").read()
old = "| `prompts-de-fase.md` | El marco común + los 18 prompts | — |"
new = """| `prompts-de-fase.md` | El marco común + los 18 prompts | — |
| `contrato-del-cli.md` | La forma del CLI fase por fase, congelada | Las fases 01-09 y 15 |"""
assert old in s
s = s.replace(old, new)
old2 = """- **[`formato-de-mediciones.md`](formato-de-mediciones.md)** — el arnés, la forma de una medición
  y las reglas de honestidad."""
new2 = """- **[`formato-de-mediciones.md`](formato-de-mediciones.md)** — el arnés, la forma de una medición
  y las reglas de honestidad.
- **[`contrato-del-cli.md`](contrato-del-cli.md)** — qué gana el CLI de Patricia en cada fase, y
  qué nombres ya están congelados. **Obligatorio antes de escribir cualquier fase entre la 01 y
  la 09, y la 15**, porque el curso se redacta fuera del orden numérico."""
assert old2 in s
io.open(p, "w", encoding="utf-8").write(s.replace(old2, new2))
print("ok")
PYEOF
ls -la *.md src/*/ 

# --- 2026-09-13T01:30:18 · Read Bloque B detailed scope
sed -n '434,560p' prompts/propuesta-fases-y-alcance.md

# --- 2026-09-13T01:30:33 · Set up pip-tools baseline
cd /tmp/claude-501 && rm -rf mgr && mkdir mgr && cd mgr && cat > reqs.in <<'EOF'
fastapi==0.141.1
sqlalchemy==2.0.52
httpx==0.28.1
pytest==9.1.1
uvicorn==0.52.4
EOF
echo "=== pip: crear venv + instalar pip-tools (frío) ==="
time (/opt/homebrew/bin/python3.14 -m venv .venv-pip && ./.venv-pip/bin/python -m pip install -q --upgrade pip pip-tools==7.6.1) 2>&1 | tail -5

# --- 2026-09-13T01:30:45 · Measure pip-tools compile and sync cold
cd /tmp/claude-501/mgr && export PIP_CACHE_DIR=/tmp/claude-501/mgr/pipcache && echo "=== pip-compile (resolución, caché vacía) ===" && time ./.venv-pip/bin/pip-compile --quiet --output-file=reqs.txt reqs.in 2>&1 | tail -3 && echo "--- líneas del lock ---" && grep -c '==' reqs.txt && echo "=== pip-sync (instalación, caché vacía) ===" && time ./.venv-pip/bin/pip-sync --quiet reqs.txt 2>&1 | tail -3 && du -sh .venv-pip

# --- 2026-09-13T01:31:14 · Benchmark pip-tools cold and warm
cd /tmp/claude-501/mgr && rm -rf .venv-pip reqs.txt pipcache && cat > run_pip.sh <<'EOF'
set -e
cd /tmp/claude-501/mgr
export PIP_CACHE_DIR=/tmp/claude-501/mgr/cache-pip
rm -rf .venv-pip reqs.txt "$PIP_CACHE_DIR"
/opt/homebrew/bin/python3.14 -m venv .venv-pip
./.venv-pip/bin/python -m pip install -q --disable-pip-version-check pip-tools==7.6.1
echo "--- compile FRIO ---"; { time ./.venv-pip/bin/pip-compile -q --no-strip-extras -o reqs.txt reqs.in ; } 2>&1 | grep real
echo "--- sync FRIO ---";    { time ./.venv-pip/bin/pip-sync -q reqs.txt ; } 2>&1 | grep real
du -sh .venv-pip | cut -f1 | xargs echo "tamaño entorno:"
echo "--- compile CALIENTE ---"; rm -f reqs.txt; { time ./.venv-pip/bin/pip-compile -q --no-strip-extras -o reqs.txt reqs.in ; } 2>&1 | grep real
echo "--- recrear entorno CALIENTE ---"
rm -rf .venv-pip2
{ time ( /opt/homebrew/bin/python3.14 -m venv .venv-pip2 && ./.venv-pip2/bin/python -m pip install -q --disable-pip-version-check -r reqs.txt ) ; } 2>&1 | grep real
grep -c '==' reqs.txt | xargs echo "paquetes en el lock:"
du -sh "$PIP_CACHE_DIR" | cut -f1 | xargs echo "caché:"
EOF
zsh run_pip.sh

# --- 2026-09-13T01:31:40 · Benchmark pip-tools with a python driver
cd /tmp/claude-501/mgr && cat > drive.py <<'PYEOF'
import subprocess, time, shutil, os, sys, pathlib

ROOT = pathlib.Path("/tmp/claude-501/mgr")

def run(cmd, env=None, cwd=ROOT, check=True):
    t0 = time.perf_counter()
    r = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=cwd,
                       env={**os.environ, **(env or {})})
    dt = time.perf_counter() - t0
    if check and r.returncode != 0:
        print("FALLO:", cmd, "\n", r.stdout[-1500:], r.stderr[-1500:])
        sys.exit(1)
    return dt

def size(p):
    p = pathlib.Path(p)
    if not p.exists(): return 0
    return sum(f.stat().st_size for f in p.rglob("*") if f.is_file()) / 1e6

PY = "/opt/homebrew/bin/python3.14"
cache = ROOT / "cache-pip"
for d in (".venv-pip", ".venv-pip2", "cache-pip", "reqs.txt"):
    shutil.rmtree(ROOT / d, ignore_errors=True) if (ROOT/d).is_dir() else (ROOT/d).unlink(missing_ok=True)

env = {"PIP_CACHE_DIR": str(cache)}
t_venv = run(f"{PY} -m venv .venv-pip", env)
run(".venv-pip/bin/python -m pip install -q --disable-pip-version-check pip-tools==7.6.1", env)

t_compile_cold = run(".venv-pip/bin/pip-compile -q --no-strip-extras -o reqs.txt reqs.in", env)
t_sync_cold = run(".venv-pip/bin/pip-sync -q reqs.txt", env)
size_env = size(ROOT/".venv-pip")

(ROOT/"reqs.txt").rename(ROOT/"reqs.keep")
t_compile_warm = run(".venv-pip/bin/pip-compile -q --no-strip-extras -o reqs.txt reqs.in", env)

shutil.rmtree(ROOT/".venv-pip2", ignore_errors=True)
t_recreate_warm = run(f"{PY} -m venv .venv-pip2 && .venv-pip2/bin/python -m pip install -q --disable-pip-version-check -r reqs.txt", env)

n = sum(1 for l in (ROOT/"reqs.txt").read_text().splitlines() if "==" in l and not l.startswith("#"))
print(f"pip+pip-tools | venv {t_venv:.1f}s | compile frío {t_compile_cold:.1f}s | install frío {t_sync_cold:.1f}s")
print(f"              | compile caliente {t_compile_warm:.1f}s | recrear entorno caliente {t_recreate_warm:.1f}s")
print(f"              | entorno {size_env:.0f} MB | caché {size(cache):.0f} MB | {n} paquetes en el lock")
PYEOF
/opt/homebrew/bin/python3.14 drive.py

# --- 2026-09-13T01:32:25 · Benchmark uv
cd /tmp/claude-501/mgr && /opt/homebrew/bin/python3.14 -m venv .tool-uv && ./.tool-uv/bin/python -m pip install -q uv==0.12.13 && ./.tool-uv/bin/uv --version && cat > drive_uv.py <<'PYEOF'
import subprocess, time, shutil, os, sys, pathlib
ROOT = pathlib.Path("/tmp/claude-501/mgr")
UV = str(ROOT/".tool-uv/bin/uv")
PY = "/opt/homebrew/bin/python3.14"
def run(cmd, env=None, check=True):
    t0=time.perf_counter()
    r=subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=ROOT, env={**os.environ, **(env or {})})
    dt=time.perf_counter()-t0
    if check and r.returncode!=0:
        print("FALLO:",cmd,"\n",r.stdout[-1500:],r.stderr[-1500:]); sys.exit(1)
    return dt
def size(p):
    p=pathlib.Path(p)
    return sum(f.stat().st_size for f in p.rglob("*") if f.is_file())/1e6 if p.exists() else 0

cache = ROOT/"cache-uv"
for d in (".venv-uv",".venv-uv2","cache-uv"): shutil.rmtree(ROOT/d, ignore_errors=True)
(ROOT/"reqs-uv.txt").unlink(missing_ok=True)
env={"UV_CACHE_DIR":str(cache)}

t_venv = run(f"{UV} venv --python {PY} .venv-uv", env)
t_compile_cold = run(f"{UV} pip compile -q --python .venv-uv/bin/python -o reqs-uv.txt reqs.in", env)
t_sync_cold = run(f"{UV} pip sync -q --python .venv-uv/bin/python reqs-uv.txt", env)
size_env = size(ROOT/".venv-uv")
t_compile_warm = run(f"{UV} pip compile -q --python .venv-uv/bin/python -o reqs-uv.txt reqs.in", env)
shutil.rmtree(ROOT/".venv-uv2", ignore_errors=True)
t_recreate_warm = run(f"{UV} venv --python {PY} .venv-uv2 && {UV} pip sync -q --python .venv-uv2/bin/python reqs-uv.txt", env)
n = sum(1 for l in (ROOT/"reqs-uv.txt").read_text().splitlines() if "==" in l and not l.startswith("#"))
print(f"uv | venv {t_venv:.1f}s | compile frío {t_compile_cold:.1f}s | install frío {t_sync_cold:.1f}s")
print(f"   | compile caliente {t_compile_warm:.1f}s | recrear entorno caliente {t_recreate_warm:.1f}s")
print(f"   | entorno {size_env:.0f} MB | caché {size(cache):.0f} MB | {n} paquetes en el lock")
PYEOF
/opt/homebrew/bin/python3.14 drive_uv.py

# --- 2026-09-13T01:32:46 · Compare bytecode and import cost
cd /tmp/claude-501/mgr && for e in .venv-pip .venv-uv; do echo -n "$e: pyc=$(find $e -name '*.pyc' | wc -l | tr -d ' ')  "; echo -n "pip presente=$(test -e $e/bin/pip && echo sí || echo no)  "; du -sh $e | cut -f1; done && echo "--- primer import de fastapi (proceso nuevo, tras crear el entorno) ---" && for e in .venv-pip .venv-uv; do echo -n "$e: "; /opt/homebrew/bin/python3.14 -c "
import subprocess,time,statistics
xs=[]
for _ in range(5):
    t0=time.perf_counter(); subprocess.run(['$e/bin/python','-c','import fastapi, sqlalchemy'],capture_output=True); xs.append((time.perf_counter()-t0)*1000)
xs.sort(); print(f'mediana {statistics.median(xs):.0f} ms')"; done

# --- 2026-09-13T01:33:02 · Measure true first import cost
cd /tmp/claude-501/mgr && rm -rf .venv-uv3 && UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv ./.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv-uv3 && UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv ./.tool-uv/bin/uv pip sync -q --python .venv-uv3/bin/python reqs-uv.txt && /opt/homebrew/bin/python3.14 -c "
import subprocess,time
for i in range(3):
    t0=time.perf_counter(); subprocess.run(['.venv-uv3/bin/python','-c','import fastapi, sqlalchemy'],capture_output=True)
    print(f'uv   import #{i+1}: {(time.perf_counter()-t0)*1000:.0f} ms')
for i in range(2):
    t0=time.perf_counter(); subprocess.run(['.venv-pip/bin/python','-c','import fastapi, sqlalchemy'],capture_output=True)
    print(f'pip  import #{i+1}: {(time.perf_counter()-t0)*1000:.0f} ms')
"

# --- 2026-09-13T01:33:13 · Download Miniforge installer
cd /tmp/claude-501/mgr && time curl -sL -o miniforge.sh "https://github.com/conda-forge/miniforge/releases/download/26.7.2-0/Miniforge3-26.7.2-0-MacOSX-arm64.sh" && ls -lh miniforge.sh

# --- 2026-09-13T01:33:21 · Install Miniforge into scratchpad
cd /tmp/claude-501/mgr && time bash miniforge.sh -b -p /tmp/claude-501/mgr/miniforge > /dev/null 2>&1; echo "exit=$?"; /tmp/claude-501/mgr/miniforge/bin/conda --version; du -sh /tmp/claude-501/mgr/miniforge

# --- 2026-09-13T01:33:47 · Create conda environment
cd /tmp/claude-501/mgr && cat > env.yml <<'EOF'
name: aurea
channels: [conda-forge]
dependencies:
  - python=3.14
  - pip
  - pip:
    - fastapi==0.141.1
    - sqlalchemy==2.0.52
    - httpx==0.28.1
    - pytest==9.1.1
    - uvicorn==0.52.4
EOF
export CONDA=/tmp/claude-501/mgr/miniforge/bin/conda
export CONDA_PKGS_DIRS=/tmp/claude-501/mgr/cache-conda
echo "=== conda env create (frío) ===" && /opt/homebrew/bin/python3.14 -c "
import subprocess,time
t0=time.perf_counter()
r=subprocess.run(['/tmp/claude-501/mgr/miniforge/bin/conda','env','create','-q','-f','env.yml','-p','/tmp/claude-501/mgr/envs/aurea'],capture_output=True,text=True,cwd='/tmp/claude-501/mgr')
print(f'{(time.perf_counter()-t0):.1f} s  exit={r.returncode}')
print(r.stderr[-800:] if r.returncode else '')
"

# --- 2026-09-13T01:34:38 · Measure conda warm recreate and imports
cd /tmp/claude-501/mgr && du -sh envs/aurea cache-conda 2>/dev/null; echo "--- recrear caliente ---"; /opt/homebrew/bin/python3.14 -c "
import subprocess,time,shutil
shutil.rmtree('/tmp/claude-501/mgr/envs/aurea2',ignore_errors=True)
t0=time.perf_counter()
r=subprocess.run(['/tmp/claude-501/mgr/miniforge/bin/conda','env','create','-q','-f','env.yml','-p','/tmp/claude-501/mgr/envs/aurea2'],capture_output=True,text=True,cwd='/tmp/claude-501/mgr')
print(f'recrear caliente: {(time.perf_counter()-t0):.1f} s exit={r.returncode}')
t0=time.perf_counter(); subprocess.run(['/tmp/claude-501/mgr/envs/aurea/bin/python','-c','import fastapi, sqlalchemy'],capture_output=True)
print(f'primer import: {(time.perf_counter()-t0)*1000:.0f} ms')
t0=time.perf_counter(); subprocess.run(['/tmp/claude-501/mgr/envs/aurea/bin/python','-c','import fastapi, sqlalchemy'],capture_output=True)
print(f'segundo import: {(time.perf_counter()-t0)*1000:.0f} ms')
"; /tmp/claude-501/mgr/envs/aurea/bin/python -V

# --- 2026-09-13T01:35:05 · Measure uv installing an interpreter
cd /tmp/claude-501/mgr && rm -rf uvpy && UV_PYTHON_INSTALL_DIR=/tmp/claude-501/mgr/uvpy UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv2 /opt/homebrew/bin/python3.14 -c "
import subprocess,time,os
env=dict(os.environ)
t0=time.perf_counter()
r=subprocess.run(['./.tool-uv/bin/uv','python','install','3.14.7'],capture_output=True,text=True,env=env)
print(f'uv python install 3.14.7: {(time.perf_counter()-t0):.1f} s exit={r.returncode}')
print((r.stderr or r.stdout)[-300:])
"; du -sh uvpy 2>/dev/null; ls uvpy 2>/dev/null

# --- 2026-09-13T01:35:30 · Build and test the package with uv
cd /tmp/claude-501 && rm -rf f07 && mkdir -p f07/src/aur && cd f07 && cat > pyproject.toml <<'EOF'
[project]
name = "aur"
version = "0.7.0"
description = "La caja de herramientas de Patricia: cierre de mes de la red Áurea."
requires-python = ">=3.13"
dependencies = []

[project.scripts]
aur = "aur.cli:main"

[dependency-groups]
dev = ["ruff==0.16.7", "pytest==9.1.1"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff]
target-version = "py314"
line-length = 100
EOF
cat > src/aur/__init__.py <<'EOF'
"""aur — la caja de herramientas de Patricia."""

__version__ = "0.7.0"
EOF
cat > src/aur/reading.py <<'EOF'
"""Lectura de los exports de las sedes."""
import csv
from pathlib import Path

def read_rows(path: Path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        yield from csv.DictReader(f)
EOF
cat > src/aur/summary.py <<'EOF'
"""Resumen del mes."""
from decimal import Decimal

def summarize(rows):
    total, patients, by_code = Decimal("0"), set(), {}
    n = 0
    for row in rows:
        n += 1
        amount = Decimal(row["valor"])
        total += amount
        patients.add(row["documento"])
        by_code[row["codigo"]] = by_code.get(row["codigo"], Decimal("0")) + amount
    return {"procedimientos": n, "pacientes": len(patients), "total": total, "por_codigo": by_code}
EOF
cat > src/aur/cli.py <<'EOF'
"""Punto de entrada de la herramienta."""
import argparse
from pathlib import Path

from aur import __version__
from aur.reading import read_rows
from aur.summary import summarize


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(prog="aur", description="Cierre de mes de la red Áurea.")
    parser.add_argument("--version", action="version", version=f"aur {__version__}")
    sub = parser.add_subparsers(dest="command", required=True)
    resumen = sub.add_parser("resumen", help="Resumen del mes de una sede.")
    resumen.add_argument("archivo", type=Path)
    args = parser.parse_args(argv)
    s = summarize(read_rows(args.archivo))
    print(f"procedimientos: {s['procedimientos']} · pacientes: {s['pacientes']} · total: ${s['total']:,.0f}")
    return 0
EOF
mkdir -p data && cp /tmp/claude-501/f01/data/centro-2026-03.csv data/ && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && time /tmp/claude-501/mgr/.tool-uv/bin/uv sync --python /opt/homebrew/bin/python3.14 2>&1 | tail -5 && ./.venv/bin/aur --version && ./.venv/bin/aur resumen data/centro-2026-03.csv && ls .venv/bin | head

# --- 2026-09-13T01:35:43 · Locate lines to adjust
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "PyCharm Community" prompts/alcance-del-proyecto.md prompts/propuesta-fases-y-alcance.md; echo "---"; grep -n "Fase 08" prompts/historia-propuesta-2-aurea.md

# --- 2026-09-13T01:35:56 · Apply the two pending one-line adjustments
python3 - <<'PYEOF'
import io

def patch(path, pairs):
    s = io.open(path, encoding="utf-8").read()
    for old, new in pairs:
        assert old in s, (path, old[:60])
        s = s.replace(old, new)
    io.open(path, "w", encoding="utf-8").write(s)
    print("ok", path)

patch("prompts/alcance-del-proyecto.md", [
 ("El ambiente de trabajo —intérprete, `pip`, `venv`, VS Code y PyCharm Community— es el ejemplo",
  "El ambiente de trabajo —intérprete, `pip`, `venv`, VS Code y PyCharm— es el ejemplo"),
 ("| Editor alternativo | PyCharm Community | Fase 00 |",
  "| Editor alternativo | **PyCharm 2026.2.2**, capa gratuita | Fase 00 |"),
 ("  extensiones y PyCharm Community, en las tres plataformas.",
  "  extensiones y PyCharm en su capa gratuita, en las tres plataformas."),
 ("""> 📅 **Fecha de verificación: 12 de septiembre de 2026.**""",
  """> 🪦 **Sobre el nombre de PyCharm.** Hasta 2025.2 el curso habría dicho *PyCharm Community
> Edition*. JetBrains descontinuó esa edición en 2025.3 y unificó el producto: hoy hay **un solo
> PyCharm** con una capa gratuita y una suscripción Pro. El curso usa la capa gratuita y declara
> en la Fase 00 qué queda del otro lado —frameworks web, herramientas de base de datos, cliente
> HTTP, desarrollo remoto y perfilador—, nada de lo cual hace falta para el camino base.

> 📅 **Fecha de verificación: 12 de septiembre de 2026.**"""),
])

patch("prompts/propuesta-fases-y-alcance.md", [
 ("| Editores | **VS Code (principal) + PyCharm Community (alternativo)** | Los dos en la Fase 00, sin apéndice |",
  "| Editores | **VS Code (principal) + PyCharm, capa gratuita (alternativo)** | Los dos en la Fase 00, sin apéndice. La Community Edition ya no existe: ver `alcance-del-proyecto.md` §9 |"),
 ("extensiones, no catorce. **PyCharm Community** como alternativa completa, con el mapa de",
  "extensiones, no catorce. **PyCharm en su capa gratuita** como alternativa completa, con el mapa de"),
])

patch("prompts/historia-propuesta-2-aurea.md", [
 ("paquete en la Fase 08 —cuando ya lo usan tres personas y hay que distribuirlo—. Es el proyecto",
  "paquete en la Fase 07 —cuando ya lo usan tres personas y hay que distribuirlo—. Es el proyecto"),
 ("demuestra para qué servía empaquetar bien en la Fase 08.",
  "demuestra para qué servía empaquetar bien en la Fase 07."),
])
PYEOF
grep -n "PyCharm" prompts/alcance-del-proyecto.md | head -5; grep -n "Fase 07 —cuando\|Fase 07\." prompts/historia-propuesta-2-aurea.md

# --- 2026-09-13T01:36:11 · Mark the two resolved pendings
python3 - <<'PYEOF'
import io
p="prompts/contrato-del-cli.md"; s=io.open(p,encoding="utf-8").read()
old="""> ⚠️ **Corrección de una contradicción de las fuentes.** `historia-propuesta-2-aurea.md` §6 dice
> que `aur` "solo se convierte en paquete en la Fase 08". La numeración oficial
> (`propuesta-fases-y-alcance.md` §4 y §7) dice **Fase 07**, y es la que manda. El curso escrito
> usa 07 en todas partes; la línea de la historia debería corregirse."""
new="""> 🪦 **Contradicción resuelta.** `historia-propuesta-2-aurea.md` §6 decía que `aur` "solo se
> convierte en paquete en la Fase 08", contra la numeración oficial de
> `propuesta-fases-y-alcance.md` §4 y §7. Ganó la numeración oficial y **la historia ya quedó
> corregida a Fase 07** (dos líneas, §6). No queda nada que conciliar."""
assert old in s; io.open(p,"w",encoding="utf-8").write(s.replace(old,new)); print("ok contrato")

p="00-ambiente-editores-y-ecosistema.md"; s=io.open(p,encoding="utf-8").read()
old="""- **`PyCharm Community` ya no existe como producto.** El alcance y la propuesta de fases nombran
  la Community Edition, que JetBrains descontinuó en 2025.3 al unificar las ediciones. Esta fase
  lo resuelve llamándolo *la capa gratuita del PyCharm unificado* y declarando qué no trae, pero
  **la decisión cerrada de `alcance-del-proyecto.md` §9 y de `propuesta-fases-y-alcance.md` §2
  debería actualizar el nombre** para que no envejezca mal. Es un cambio de una línea en cada
  documento."""
new="""- 🪦 **`PyCharm Community` ya no existe como producto**, y las fuentes de verdad ya no lo
  nombran: `alcance-del-proyecto.md` §9 y `propuesta-fases-y-alcance.md` §2 quedaron actualizados
  a *PyCharm 2026.2.2, capa gratuita*, con la nota 🪦 que explica la unificación de 2025.3. Esta
  fase es la única que describe qué queda del lado Pro."""
assert old in s; io.open(p,"w",encoding="utf-8").write(s.replace(old,new)); print("ok fase00")
PYEOF

# --- 2026-09-13T01:42:07 · Measure uv tool install
cd /tmp/claude-501/f07 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && export PATH=/tmp/claude-501/mgr/.tool-uv/bin:$PATH
echo "=== 1. uv tool install (aislado) ==="
rm -rf /tmp/claude-501/uvtools
UV_TOOL_DIR=/tmp/claude-501/uvtools UV_TOOL_BIN_DIR=/tmp/claude-501/uvbin /opt/homebrew/bin/python3.14 -c "
import subprocess,time,os
t0=time.perf_counter()
r=subprocess.run(['uv','tool','install','--python','/opt/homebrew/bin/python3.14','.'],capture_output=True,text=True,env=dict(os.environ))
print(f'uv tool install: {(time.perf_counter()-t0):.1f}s exit={r.returncode}'); print((r.stderr or '')[-400:])
"
du -sh /tmp/claude-501/uvtools 2>/dev/null; ls /tmp/claude-501/uvbin 2>/dev/null
echo "=== arranque ==="
/opt/homebrew/bin/python3.14 -c "
import subprocess,time,statistics
xs=[]
for _ in range(10):
    t0=time.perf_counter(); subprocess.run(['/tmp/claude-501/uvbin/aur','--version'],capture_output=True); xs.append((time.perf_counter()-t0)*1000)
xs.sort(); print(f'mediana {statistics.median(xs):.0f} ms  p95 {xs[8]:.0f} ms')"

# --- 2026-09-13T01:42:20 · Build and measure zipapp
cd /tmp/claude-501/f07 && echo "=== 2. zipapp ===" && rm -rf build-pyz && mkdir build-pyz && cp -r src/aur build-pyz/ && /opt/homebrew/bin/python3.14 -c "
import zipapp, time, pathlib
t0=time.perf_counter()
zipapp.create_archive('build-pyz', target='aur.pyz', main='aur.cli:main', interpreter='/usr/bin/env python3')
print(f'zipapp build: {(time.perf_counter()-t0)*1000:.0f} ms  tamaño: {pathlib.Path(\"aur.pyz\").stat().st_size/1024:.0f} KB')
import subprocess, statistics
xs=[]
for _ in range(10):
    t1=time.perf_counter(); subprocess.run(['/opt/homebrew/bin/python3.14','aur.pyz','--version'],capture_output=True); xs.append((time.perf_counter()-t1)*1000)
xs.sort(); print(f'arranque: mediana {statistics.median(xs):.0f} ms')
r=subprocess.run(['/opt/homebrew/bin/python3.14','aur.pyz','--version'],capture_output=True,text=True); print('salida:', r.stdout.strip() or r.stderr.strip()[:200])
"

# --- 2026-09-13T01:42:29 · Measure PEP 723 inline script
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

# --- 2026-09-13T01:42:37 · Measure PEP 723 cold
cd /tmp/claude-501/f07 && rm -rf /tmp/claude-501/cache-pep723 && UV_CACHE_DIR=/tmp/claude-501/cache-pep723 /opt/homebrew/bin/python3.14 -c "
import subprocess,time,os
env=dict(os.environ)
t0=time.perf_counter()
r=subprocess.run(['/tmp/claude-501/mgr/.tool-uv/bin/uv','run','cierre.py'],capture_output=True,text=True,env=env)
print(f'uv run con caché FRIA: {(time.perf_counter()-t0):.1f}s ->', r.stdout.strip())
"; du -sh /tmp/claude-501/cache-pep723

# --- 2026-09-13T01:42:51 · Build frozen executable with PyInstaller
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

# --- 2026-09-13T01:43:47 · Measure onedir frozen build
cd /tmp/claude-501/f07 && /opt/homebrew/bin/python3.14 -c "
import subprocess,time,pathlib,statistics
t0=time.perf_counter()
r=subprocess.run(['.venv/bin/pyinstaller','--onedir','--name','aurdir','--paths','src','--clean','-y',
                  '--specpath','build-spec','--distpath','dist-dir','--workpath','build-work2',
                  'src/aur/__main__entry.py'],capture_output=True,text=True)
print(f'build onedir: {(time.perf_counter()-t0):.1f}s exit={r.returncode}')
p=pathlib.Path('dist-dir/aurdir/aurdir')
total=sum(f.stat().st_size for f in pathlib.Path('dist-dir/aurdir').rglob('*') if f.is_file())
print(f'tamaño carpeta: {total/1e6:.1f} MB · archivos: {sum(1 for _ in pathlib.Path(\"dist-dir/aurdir\").rglob(\"*\") if _.is_file())}')
xs=[]
for _ in range(10):
    t1=time.perf_counter(); subprocess.run([str(p),'--version'],capture_output=True); xs.append((time.perf_counter()-t1)*1000)
xs.sort(); print(f'arranque onedir: mediana {statistics.median(xs):.0f} ms')
"

# --- 2026-09-13T01:48:32 · Verify documented zipapp command
cd /tmp/claude-501/f07 && rm -rf build-pyz aur.pyz && mkdir build-pyz && cp -r src/aur build-pyz/ && /opt/homebrew/bin/python3.14 -m zipapp build-pyz --output aur.pyz --main "aur.cli:main" --python "/usr/bin/env python3" && ls -l aur.pyz && /opt/homebrew/bin/python3.14 aur.pyz --version && echo "--- ¿ejecutable directo? ---" && chmod +x aur.pyz && ./aur.pyz --version 2>&1 | head -2

# --- 2026-09-13T01:48:46 · Update contract and clean scratch
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p="09-distribucion.md"; s=io.open(p,encoding="utf-8").read()
old="""**6 KB.** Un archivo, que se manda por correo, que se copia a una carpeta compartida, y que no
instala nada en ninguna parte."""
new="""**6.9 KB.** Un archivo, que se manda por correo, que se copia a una carpeta compartida, y que no
instala nada en ninguna parte. Y como la cabecera lleva el `#!`, en Linux y macOS basta con
`chmod +x aur.pyz` para que `./aur.pyz` funcione directo — comprobado."""
assert old in s; io.open(p,"w",encoding="utf-8").write(s.replace(old,new))

p="prompts/contrato-del-cli.md"; s=io.open(p,encoding="utf-8").read()
old="""| **15** | El proceso nocturno **importa `aur` como biblioteca**"""
new="""| **09** | *(decisión tomada al escribir la fase)* El `if __name__ == "__main__":` de `cli.py` **se queda**: el `.pyz` y el ejecutable congelado lo necesitan. Ninguna fase posterior lo borra por limpieza | |
| **15** | El proceso nocturno **importa `aur` como biblioteca**"""
assert old in s; io.open(p,"w",encoding="utf-8").write(s.replace(old,new))
print("ok")
PYEOF
rm -rf /tmp/claude-501/mgr/miniforge /tmp/claude-501/mgr/miniforge.sh /tmp/claude-501/mgr/envs /tmp/claude-501/mgr/cache-conda /tmp/claude-501/f07/build-work /tmp/claude-501/f07/build-work2 /tmp/claude-501/f07/dist-dir && du -sh /tmp/claude-501 && ls *.md

# --- 2026-09-13T01:49:03 · Fix table cell and trim scratch
python3 - <<'PYEOF'
import io
p="09-distribucion.md"; s=io.open(p,encoding="utf-8").read()
old="| Tamaño del entregable | 128 KB *(entorno)* | **6 KB** | **1 archivo** | 8.4 MB | 31.2 MB, 49 archivos |"
new="| Tamaño del entregable | 128 KB *(entorno)* | **6.9 KB** | **1 archivo** | 8.4 MB | 31.2 MB, 49 archivos |"
assert old in s; io.open(p,"w",encoding="utf-8").write(s.replace(old,new)); print("ok")
PYEOF
ls -la *.md && rm -rf /tmp/claude-501/mgr/.venv-pip /tmp/claude-501/mgr/.venv-pip2 /tmp/claude-501/mgr/.venv-uv /tmp/claude-501/mgr/.venv-uv2 /tmp/claude-501/mgr/.venv-uv3 && du -sh /tmp/claude-501

# --- 2026-09-13T01:50:21 · Check packaging tool versions
for p in hatchling pyinstaller pipx shiv nuitka; do echo -n "$p -> "; curl -s "https://pypi.org/pypi/$p/json" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['info']['version'], d['urls'][0]['upload_time'][:10] if d['urls'] else '')" 2>/dev/null || echo n/a; done

# --- 2026-09-13T01:50:31 · Pin hatchling and PyInstaller in the version table
python3 - <<'PYEOF'
import io
p="prompts/alcance-del-proyecto.md"; s=io.open(p,encoding="utf-8").read()
old = """| Editor principal | VS Code + extensión oficial de Python | Fase 00 |"""
new = """| Backend de empaquetado | `hatchling` **1.32.0** | Fase 07 en adelante |
| Distribución | `PyInstaller` **6.22.3** · `zipapp` (biblioteca estándar) · `uv tool` | Fase 09 |
| Editor principal | VS Code + extensión oficial de Python | Fase 00 |"""
assert old in s; s = s.replace(old, new)
io.open(p,"w",encoding="utf-8").write(s); print("ok")
PYEOF
sed -n '/| Herramienta | Versión | Dónde vive |/,/^$/p' prompts/alcance-del-proyecto.md | head -16

# --- 2026-09-13T01:50:43 · Pin hatchling in the example and re-verify it builds
python3 - <<'PYEOF'
import io
p="07-cuando-deja-de-ser-un-script.md"; s=io.open(p,encoding="utf-8").read()
old = """[build-system]
# Quién sabe convertir este directorio en un paquete instalable. En Python el
# empaquetador es una dependencia elegible, no parte del lenguaje.
requires = ["hatchling"]
build-backend = "hatchling.build\""""
new = """[build-system]
# Quién sabe convertir este directorio en un paquete instalable. En Python el
# empaquetador es una dependencia elegible, no parte del lenguaje — por eso hay
# que nombrarlo, y por eso va con su piso de versión como todo lo demás.
requires = ["hatchling>=1.32"]
build-backend = "hatchling.build\""""
assert old in s; io.open(p,"w",encoding="utf-8").write(s.replace(old,new)); print("ok")
PYEOF
cd /tmp/claude-501/f07 && sed -i '' 's/requires = \["hatchling"\]/requires = ["hatchling>=1.32"]/' pyproject.toml && UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv /tmp/claude-501/mgr/.tool-uv/bin/uv sync -q --python /opt/homebrew/bin/python3.14 && ./.venv/bin/aur --version

# --- 2026-09-13T01:50:52 · Read detailed scope of phases 03-06
cd cursos-algoritmos-lenguajes/python-for-java-devs && sed -n '300,440p' prompts/propuesta-fases-y-alcance.md

# --- 2026-09-13T01:51:10 · Generate the 500k appointments file
mkdir -p /tmp/claude-501/f02 && cd /tmp/claude-501/f02 && cat > generar_citas.py <<'PYEOF'
"""Genera el archivo de citas del primer trimestre de 2026 de toda la red.

Uso:  python generar_citas.py
Produce data/citas-2026-Q1.csv, unas 500.000 filas, con semilla fija.
Es el archivo grande del curso: las fases 02, 06, 14, 15 y 16 lo usan.
"""

import random
from datetime import date, timedelta
from pathlib import Path

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]
STATUSES = ["asistio", "no_show", "cancelada", "reprogramada"]
WEIGHTS = [76, 19, 3, 2]          # el 19% de inasistencia es dato del dominio
CODES = ["D8010", "D8020", "D2740", "D7140", "D1110", "D8670"]


def main() -> None:
    random.seed(2026)
    Path("data").mkdir(exist_ok=True)
    target = Path("data") / "citas-2026-Q1.csv"

    start = date(2026, 1, 1)
    with target.open("w", encoding="utf-8", newline="\n") as file:
        file.write("documento,sede,fecha,hora,estado,codigo,valor\n")
        rows = 0
        for day_offset in range(90):
            day = start + timedelta(days=day_offset)
            if day.weekday() == 6:          # domingo no se atiende
                continue
            for branch in BRANCHES:
                for _ in range(random.randint(550, 700)):
                    document = random.randint(10_000_000, 1_299_999_999)
                    hour = random.randint(7, 18)
                    minute = random.choice((0, 20, 40))
                    status = random.choices(STATUSES, WEIGHTS)[0]
                    code = random.choice(CODES)
                    value = random.choice((75000, 95000, 120000, 180000, 210000, 890000))
                    file.write(f"{document},{branch},{day.isoformat()},"
                               f"{hour:02d}:{minute:02d},{status},{code},{value}\n")
                    rows += 1
    size_mb = target.stat().st_size / 1e6
    print(f"{target}: {rows:,} filas · {size_mb:.1f} MB")


if __name__ == "__main__":
    main()
PYEOF
time /opt/homebrew/bin/python3.14 generar_citas.py

# --- 2026-09-13T01:51:31 · Build harness and measure eager vs lazy
cd /tmp/claude-501/f02 && cat > bench.py <<'PYEOF'
"""El arnés de medición del curso. Biblioteca estándar, y nada más.

Tres responsabilidades y ninguna más: cronometrar con reloj monótono y
repeticiones, medir el pico de memoria, y declarar el entorno.

Uso:
    from bench import measure, environment
    print(environment())
    print(measure("tubería perezosa", lambda: report(path)))
"""

import platform
import statistics
import sys
import time
import tracemalloc
from collections.abc import Callable
from typing import Any


def environment() -> str:
    """Sin esto, un número no es reproducible y por lo tanto no es un número."""
    return (
        f"{platform.python_implementation()} {platform.python_version()} · "
        f"{platform.system()} {platform.release()} · {platform.machine()}"
    )


def measure(label: str, work: Callable[[], Any], repetitions: int = 5) -> dict[str, Any]:
    """Ejecuta `work` varias veces y devuelve tiempos y pico de memoria.

    Se reportan mediana y percentil 95, nunca el promedio solo: el promedio
    esconde la cola, que es justo lo que importa cuando algo se degrada.
    El pico de memoria se mide en una corrida aparte, porque tracemalloc
    distorsiona el tiempo.
    """
    timings: list[float] = []
    for _ in range(repetitions):
        started = time.perf_counter()
        work()
        timings.append((time.perf_counter() - started) * 1000)
    timings.sort()

    tracemalloc.start()
    work()
    _, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()

    return {
        "etiqueta": label,
        "mediana_ms": statistics.median(timings),
        "p95_ms": timings[max(0, int(len(timings) * 0.95) - 1)],
        "pico_mb": peak / 1e6,
        "repeticiones": repetitions,
    }


def render(results: list[dict[str, Any]]) -> str:
    """La tabla, lista para pegar en el documento de la fase."""
    lines = [f"Entorno: {environment()}", ""]
    lines.append(f"{'opción':<28}{'mediana':>12}{'p95':>12}{'pico':>12}")
    for result in results:
        lines.append(
            f"{result['etiqueta']:<28}{result['mediana_ms']:>10.0f} ms"
            f"{result['p95_ms']:>10.0f} ms{result['pico_mb']:>9.1f} MB"
        )
    return "\n".join(lines)


if __name__ == "__main__":
    print(environment(), file=sys.stderr)
PYEOF
cat > medir_f02.py <<'PYEOF'
from pathlib import Path
from bench import measure, render

PATH = Path("data/citas-2026-Q1.csv")

def eager(path):
    """Lo que escribe alguien que viene de Java: la lista completa, y después se filtra."""
    with path.open(encoding="utf-8") as f:
        lines = f.readlines()[1:]
    rows = [line.rstrip("\n").split(",") for line in lines]
    no_shows = [r for r in rows if r[4] == "no_show"]
    by_branch = {}
    for r in no_shows:
        by_branch[r[1]] = by_branch.get(r[1], 0) + 1
    return by_branch

def lazy(path):
    """La tubería perezosa: nada se materializa salvo el resultado."""
    with path.open(encoding="utf-8") as f:
        next(f)
        rows = (line.rstrip("\n").split(",") for line in f)
        no_shows = (r for r in rows if r[4] == "no_show")
        by_branch = {}
        for r in no_shows:
            by_branch[r[1]] = by_branch.get(r[1], 0) + 1
    return by_branch

assert eager(PATH) == lazy(PATH)
print(render([
    measure("lista intermedia", lambda: eager(PATH)),
    measure("tubería perezosa", lambda: lazy(PATH)),
]))
PYEOF
/opt/homebrew/bin/python3.14 medir_f02.py

# --- 2026-09-13T01:51:47 · Measure threshold across file sizes
cd /tmp/claude-501/f02 && /opt/homebrew/bin/python3.14 - <<'EOF'
from pathlib import Path
import itertools, importlib.util, sys
sys.path.insert(0,'.')
from bench import measure
from medir_f02 import eager, lazy
src = Path("data/citas-2026-Q1.csv")
lines = src.read_text(encoding="utf-8").splitlines(keepends=True)
head, body = lines[0], lines[1:]
for n in (1000, 10_000, 50_000, 200_000, 482_074):
    p = Path(f"data/sub-{n}.csv"); p.write_text(head + "".join(body[:n]), encoding="utf-8")
    e = measure("e", lambda: eager(p), 3); l = measure("l", lambda: lazy(p), 3)
    print(f"n={n:>7,}  lista {e['mediana_ms']:7.1f} ms / {e['pico_mb']:6.1f} MB   perezosa {l['mediana_ms']:7.1f} ms / {l['pico_mb']:5.2f} MB")
    p.unlink()
EOF

# --- 2026-09-13T01:56:39 · Verify reference solution and groupby claim
cd /tmp/claude-501/f02 && python3 - <<'EOF'
import re, pathlib
doc = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/02-secuencias-perezosas.md").read_text()
blocks = re.findall(r"```python\n(.*?)```", doc, re.S)
sol = [b for b in blocks if b.startswith('"""Informe trimestral')][0]
pathlib.Path("informe_inasistencia.py").write_text(sol)
EOF
/opt/homebrew/bin/python3.14 informe_inasistencia.py data/citas-2026-Q1.csv | head -6 && echo "--- pico de memoria ---" && /opt/homebrew/bin/python3.14 -c "
import sys; sys.path.insert(0,'.')
from bench import measure, render
from pathlib import Path
from informe_inasistencia import tally, rows_of
p=Path('data/citas-2026-Q1.csv')
print(render([measure('informe', lambda: tally(rows_of(p)), 3)]))
" && echo "--- cuántos grupos da groupby sin ordenar ---" && /opt/homebrew/bin/python3.14 -c "
import itertools
from informe_inasistencia import rows_of
from pathlib import Path
gs = sum(1 for _ in itertools.groupby(rows_of(Path('data/citas-2026-Q1.csv')), key=lambda r: r[1]))
print('grupos:', gs)"

# --- 2026-09-13T01:56:52 · Correct the group count and add F02 assets
cd cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p="02-secuencias-perezosas.md"; s=io.open(p,encoding="utf-8").read()
old="""plausible y equivocado: como el archivo viene ordenado por fecha y dentro de cada día por sede,
salen unos 890 grupos (una por sede y día) en vez de diez, y si los acumulas en un diccionario
por error **el resultado final incluso coincide**."""
new="""plausible y equivocado: como el archivo viene ordenado por fecha y dentro de cada día por sede,
salen **770 grupos** —diez sedes por los setenta y siete días hábiles del trimestre— en vez de
diez, y si los acumulas en un diccionario por error **el resultado final incluso coincide**."""
assert old in s; io.open(p,"w",encoding="utf-8").write(s.replace(old,new)); print("ok")
PYEOF
mkdir -p src/02-secuencias-perezosas && cp /tmp/claude-501/f02/generar_citas.py /tmp/claude-501/f02/bench.py src/02-secuencias-perezosas/ && ls src/*/

# --- 2026-09-13T01:57:17 · Measure dataclass vs dict vs NamedTuple
mkdir -p /tmp/claude-501/f03 && cd /tmp/claude-501/f03 && cat > medir_registros.py <<'PYEOF'
import sys, random, statistics, time, tracemalloc
from dataclasses import dataclass
from typing import NamedTuple

N = 100_000
random.seed(2026)
raw = [(str(random.randint(10_000_000, 1_299_999_999)), random.choice(["Centro","Suba","Kennedy"]),
        "2026-03-14", "D8010", 180000) for _ in range(N)]

@dataclass
class ApptDC:
    document: str; branch: str; date: str; code: str; amount: int

@dataclass(slots=True)
class ApptSlots:
    document: str; branch: str; date: str; code: str; amount: int

class ApptNT(NamedTuple):
    document: str; branch: str; date: str; code: str; amount: int

def build_dict(): return [{"document":d,"branch":b,"date":f,"code":c,"amount":a} for d,b,f,c,a in raw]
def build_tuple(): return [t for t in raw]
def build_dc(): return [ApptDC(*t) for t in raw]
def build_slots(): return [ApptSlots(*t) for t in raw]
def build_nt(): return [ApptNT(*t) for t in raw]

def peak(fn):
    tracemalloc.start(); obj = fn(); _, pk = tracemalloc.get_traced_memory(); tracemalloc.stop()
    return pk/1e6, obj

def access(objs, kind):
    t0=time.perf_counter()
    if kind=="dict": s=sum(o["amount"] for o in objs)
    elif kind=="tuple": s=sum(o[4] for o in objs)
    else: s=sum(o.amount for o in objs)
    return (time.perf_counter()-t0)*1000

for name,fn,kind in [("tuple",build_tuple,"tuple"),("dict",build_dict,"dict"),
                     ("dataclass",build_dc,"attr"),("dataclass(slots)",build_slots,"attr"),
                     ("NamedTuple",build_nt,"attr")]:
    pk, objs = peak(fn)
    times=[access(objs,kind) for _ in range(7)]; times.sort()
    t0=time.perf_counter(); fn(); build_ms=(time.perf_counter()-t0)*1000
    print(f"{name:<18} memoria {pk:7.1f} MB · construir {build_ms:7.0f} ms · acceso {statistics.median(times):6.1f} ms")
PYEOF
/opt/homebrew/bin/python3.14 medir_registros.py

# --- 2026-09-13T01:57:27 · Re-measure with fair tuple construction
cd /tmp/claude-501/f03 && sed -i '' 's/def build_tuple(): return \[t for t in raw\]/def build_tuple(): return [tuple(t) for t in raw]/' medir_registros.py && /opt/homebrew/bin/python3.14 medir_registros.py

# --- 2026-09-13T01:57:35 · Fix tuple construction and verify the identity gotcha
cd /tmp/claude-501/f03 && sed -i '' 's/def build_tuple(): return \[tuple(t) for t in raw\]/def build_tuple(): return [(d, b, f, c, a) for d, b, f, c, a in raw]/' medir_registros.py && /opt/homebrew/bin/python3.14 medir_registros.py && /opt/homebrew/bin/python3.14 -c "
t=(1,2,3); print('tuple(t) is t ->', tuple(t) is t)"

# --- 2026-09-13T01:58:08 · Compare both commission engine styles
cd /tmp/claude-501/f03 && cat > estilo_java.py <<'PYEOF'
"""El motor de comisiones escrito con el reflejo de Java: jerarquía de estrategias."""

from abc import ABC, abstractmethod
from decimal import Decimal


class ReferralFeePolicy(ABC):
    """Contrato de cálculo de la comisión de un aliado."""

    @abstractmethod
    def calculate(self, treatment_value: Decimal, specialty: str,
                  month_to_date: Decimal) -> Decimal:
        ...


class PercentagePolicy(ReferralFeePolicy):
    def __init__(self, percentage: Decimal) -> None:
        self._percentage = percentage

    def calculate(self, treatment_value, specialty, month_to_date):
        return treatment_value * self._percentage


class MinimumPerCasePolicy(ReferralFeePolicy):
    def __init__(self, percentage: Decimal, minimum: Decimal) -> None:
        self._percentage = percentage
        self._minimum = minimum

    def calculate(self, treatment_value, specialty, month_to_date):
        return max(treatment_value * self._percentage, self._minimum)


class MonthlyCapPolicy(ReferralFeePolicy):
    def __init__(self, percentage: Decimal, cap: Decimal) -> None:
        self._percentage = percentage
        self._cap = cap

    def calculate(self, treatment_value, specialty, month_to_date):
        fee = treatment_value * self._percentage
        remaining = self._cap - month_to_date
        return min(fee, max(remaining, Decimal("0")))


class BySpecialtyPolicy(ReferralFeePolicy):
    def __init__(self, default: Decimal, by_specialty: dict[str, Decimal]) -> None:
        self._default = default
        self._by_specialty = by_specialty

    def calculate(self, treatment_value, specialty, month_to_date):
        return treatment_value * self._by_specialty.get(specialty, self._default)


class ReferralFeePolicyFactory:
    """Construye la política de cada aliado."""

    def __init__(self) -> None:
        self._policies: dict[str, ReferralFeePolicy] = {}

    def register(self, partner_id: str, policy: ReferralFeePolicy) -> None:
        self._policies[partner_id] = policy

    def get(self, partner_id: str) -> ReferralFeePolicy:
        if partner_id not in self._policies:
            raise KeyError(f"aliado sin política registrada: {partner_id}")
        return self._policies[partner_id]


class ReferralFeeCalculator:
    def __init__(self, factory: ReferralFeePolicyFactory) -> None:
        self._factory = factory

    def calculate(self, partner_id, treatment_value, specialty, month_to_date):
        return self._factory.get(partner_id).calculate(
            treatment_value, specialty, month_to_date
        )


def build_factory() -> ReferralFeePolicyFactory:
    factory = ReferralFeePolicyFactory()
    factory.register("P001", PercentagePolicy(Decimal("0.15")))
    factory.register("P002", PercentagePolicy(Decimal("0.12")))
    factory.register("P003", PercentagePolicy(Decimal("0.20")))
    factory.register("P004", MinimumPerCasePolicy(Decimal("0.10"), Decimal("150000")))
    factory.register("P005", MonthlyCapPolicy(Decimal("0.18"), Decimal("2000000")))
    factory.register("P006", BySpecialtyPolicy(
        Decimal("0.10"), {"implantologia": Decimal("0.20"), "endodoncia": Decimal("0.12")}))
    return factory
PYEOF
cat > estilo_python.py <<'PYEOF'
"""El motor de comisiones sin ceremonia: una tabla de datos y tres excepciones."""

from decimal import Decimal

# Los veinte aliados ordinarios no son código: son datos. Agregar el aliado 24
# es una línea en este diccionario —o una fila en el archivo del que salga—.
PARTNER_RATES: dict[str, Decimal] = {
    "P001": Decimal("0.15"),
    "P002": Decimal("0.12"),
    "P003": Decimal("0.20"),
    "P004": Decimal("0.10"),
    "P005": Decimal("0.18"),
    "P006": Decimal("0.10"),
}

# Y las tres excepciones son tres funciones, registradas con un decorador.
SPECIAL_RULES: dict[str, callable] = {}


def rule_for(partner_id: str):
    """Registra la regla especial de un aliado. Agregar una no toca nada existente."""
    def register(function):
        SPECIAL_RULES[partner_id] = function
        return function
    return register


@rule_for("P004")
def minimum_per_case(value, specialty, month_to_date, rate):
    """Neira cobra un mínimo por caso, por barato que salga el tratamiento."""
    return max(value * rate, Decimal("150000"))


@rule_for("P005")
def monthly_cap(value, specialty, month_to_date, rate):
    """Buitrago negoció un tope mensual: pasado ese punto, no se causa más."""
    return min(value * rate, max(Decimal("2000000") - month_to_date, Decimal("0")))


@rule_for("P006")
def by_specialty(value, specialty, month_to_date, rate):
    """Cárdenas cobra distinto según la especialidad del procedimiento."""
    rates = {"implantologia": Decimal("0.20"), "endodoncia": Decimal("0.12")}
    return value * rates.get(specialty, rate)


def referral_fee(partner_id, value, specialty="", month_to_date=Decimal("0")):
    """La comisión de un caso. Una función, y es toda la interfaz pública."""
    rate = PARTNER_RATES[partner_id]
    rule = SPECIAL_RULES.get(partner_id)
    return rule(value, specialty, month_to_date, rate) if rule else value * rate
PYEOF
/opt/homebrew/bin/python3.14 -c "
from decimal import Decimal
import estilo_java as j, estilo_python as p
calc = j.ReferralFeeCalculator(j.build_factory())
casos = [('P001', Decimal('1000000'), '', Decimal('0')),
         ('P004', Decimal('500000'), '', Decimal('0')),
         ('P005', Decimal('1000000'), '', Decimal('1900000')),
         ('P006', Decimal('1000000'), 'implantologia', Decimal('0'))]
for pid, v, s, m in casos:
    a = calc.calculate(pid, v, s, m); b = p.referral_fee(pid, v, s, m)
    print(f'{pid}: java={a}  python={b}  {\"OK\" if a==b else \"DIFIEREN\"}')
"
echo "--- líneas de código (sin docstrings ni vacías) ---"
for f in estilo_java.py estilo_python.py; do echo -n "$f: "; grep -v '^\s*$' $f | grep -v '^\s*#' | grep -vc '^\s*"""'; done

# --- 2026-09-13T01:58:19 · Rigorous LOC count without docstrings
cd /tmp/claude-501/f03 && /opt/homebrew/bin/python3.14 - <<'EOF'
import ast, pathlib
for f in ("estilo_java.py", "estilo_python.py"):
    src = pathlib.Path(f).read_text()
    tree = ast.parse(src)
    # quita docstrings
    for node in ast.walk(tree):
        if isinstance(node, (ast.Module, ast.ClassDef, ast.FunctionDef, ast.AsyncFunctionDef)):
            if node.body and isinstance(node.body[0], ast.Expr) and isinstance(node.body[0].value, ast.Constant) and isinstance(node.body[0].value.value, str):
                node.body.pop(0)
    code = ast.unparse(tree)
    loc = len([l for l in code.splitlines() if l.strip()])
    stmts = sum(1 for n in ast.walk(tree) if isinstance(n, ast.stmt))
    classes = sum(1 for n in ast.walk(tree) if isinstance(n, ast.ClassDef))
    funcs = sum(1 for n in ast.walk(tree) if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)))
    print(f"{f:<20} líneas {loc:>3} · sentencias {stmts:>3} · clases {classes} · funciones {funcs}")
EOF

# --- 2026-09-13T02:03:32 · Verify the commission engine end to end
cd /tmp/claude-501/f03 && python3 - <<'EOF'
import re, pathlib
doc = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/03-python-sin-ceremonia.md").read_text()
blocks = re.findall(r"```python\n(.*?)```", doc, re.S)
motor = [b for b in blocks if b.startswith('"""El motor de comisiones de aliados')][0]
gen = [b for b in blocks if b.startswith('"""Genera las derivaciones')][0]
settle = [b for b in blocks if b.startswith('from collections import defaultdict')][0]
pathlib.Path("comisiones.py").write_text(motor + "\n\n" + settle)
pathlib.Path("generar_derivaciones.py").write_text(gen)
EOF
/opt/homebrew/bin/python3.14 generar_derivaciones.py && /opt/homebrew/bin/python3.14 -c "
from decimal import Decimal
from dataclasses import dataclass
import comisiones as c

@dataclass(frozen=True, slots=True)
class Referral:
    partner_id: str; branch: str; date: str; specialty: str; treatment_value: Decimal

rows=[]
for line in open('data/derivaciones-2026-Q1.csv',encoding='utf-8').read().splitlines()[1:]:
    p,b,f,e,v = line.split(',')
    if p in c.PARTNER_RATES: rows.append(Referral(p,b,f,e,Decimal(v)))
print('derivaciones con tasa conocida:', len(rows))
tot = c.settle_quarter(rows)
for k in sorted(tot): print(f'  {k}: \${tot[k]:,.0f}')
print()
print('P001 1.000.000 ->', c.referral_fee('P001', Decimal('1000000')))
print('P004 500.000   ->', c.referral_fee('P004', Decimal('500000')))
print('P005 tope      ->', c.referral_fee('P005', Decimal('1000000'), month_to_date=Decimal('1900000')))
print('P006 implante  ->', c.referral_fee('P006', Decimal('1000000'), 'implantologia'))
"

# --- 2026-09-13T02:03:48 · Measure EAFP vs LBYL across failure rates
mkdir -p /tmp/claude-501/f04 && cd /tmp/claude-501/f04 && cp /tmp/claude-501/f02/bench.py . && cat > medir_eafp.py <<'PYEOF'
"""EAFP contra LBYL en el caso feliz y en el caso malo, variando la tasa de fallo."""
import random, statistics, time

random.seed(2026)
N = 200_000

def make_rows(bad_rate):
    rows = []
    for _ in range(N):
        if random.random() < bad_rate:
            rows.append({"documento": "1019", "valor": ""})        # vacío: no convertible
        else:
            rows.append({"documento": "1019", "valor": str(random.randint(1, 900000))})
    return rows

def lbyl(rows):
    total = 0
    for row in rows:
        value = row.get("valor", "")
        if value and value.isdigit():        # comprobar antes
            total += int(value)
    return total

def eafp(rows):
    total = 0
    for row in rows:
        try:
            total += int(row["valor"])        # intentar y fallar
        except (KeyError, ValueError):
            pass
    return total

def bench(fn, rows, reps=7):
    xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(rows); xs.append((time.perf_counter()-t0)*1000)
    xs.sort(); return statistics.median(xs)

print(f"{'fallos':>8} {'LBYL':>10} {'EAFP':>10}  veredicto")
for rate in (0.0, 0.01, 0.05, 0.10, 0.25, 0.50, 1.0):
    rows = make_rows(rate)
    assert lbyl(rows) == eafp(rows)
    a, b = bench(lbyl, rows), bench(eafp, rows)
    who = "EAFP" if b < a else "LBYL"
    print(f"{rate*100:7.0f}% {a:8.1f} ms {b:8.1f} ms  gana {who} ({abs(a-b)/max(a,b)*100:.0f}% de diferencia)")
PYEOF
/opt/homebrew/bin/python3.14 medir_eafp.py

# --- 2026-09-13T02:04:01 · Save F03 asset
cd cursos-algoritmos-lenguajes/python-for-java-devs && mkdir -p src/03-python-sin-ceremonia && cp /tmp/claude-501/f03/generar_derivaciones.py src/03-python-sin-ceremonia/ && ls src/*/

# --- 2026-09-13T02:08:51 · Verify the seeded problem counts
mkdir -p /tmp/claude-501/f04 && cd /tmp/claude-501/f04 && python3 - <<'EOF'
import re, pathlib
doc = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/04-errores-y-recursos.md").read_text()
gen = [b for b in re.findall(r"```python\n(.*?)```", doc, re.S) if b.startswith('"""Genera el lote de febrero')][0]
pathlib.Path("generar_lote_febrero.py").write_text(gen)
EOF
/opt/homebrew/bin/python3.14 generar_lote_febrero.py && /opt/homebrew/bin/python3.14 - <<'EOF'
from datetime import date
from decimal import Decimal, InvalidOperation
from collections import Counter
BR={"Centro","Chapinero","Suba","Kennedy","Usaquen","Engativa","Fontibon","Restrepo","Soacha","Zipaquira"}
CODES={"D8010","D8020","D2740","D7140","D1110","D8670"}
kinds=Counter(); seen={}; dups=0
for i,line in enumerate(open("data/lote-2026-02.csv",encoding="utf-8").read().splitlines()[1:], start=2):
    d,p,b,f,c,v = line.split(",")
    if not d.strip().isdigit(): kinds["documento"]+=1
    if b not in BR: kinds["sede"]+=1
    try: date.fromisoformat(f)
    except ValueError: kinds["fecha"]+=1
    try:
        if Decimal(v) <= 0: kinds["valor<=0"]+=1
    except InvalidOperation: kinds["valor no numérico"]+=1
    if c not in CODES: kinds["codigo"]+=1
    k=(d,c,f)
    if k in seen: dups+=1
    else: seen[k]=i
print("problemas por clase:", dict(kinds))
print("total problemas de fila:", sum(kinds.values()), "| duplicados:", dups, "| clases:", len(kinds)+1)
EOF

# --- 2026-09-13T02:09:12 · Fix the problem count and save the asset
cd cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p="04-errores-y-recursos.md"; s=io.open(p,encoding="utf-8").read()
old = """Uso:  python generar_lote_febrero.py
Produce data/lote-2026-02.csv con 6.000 filas y 47 problemas repartidos.
\"\"\""""
new = """Uso:  python generar_lote_febrero.py
Produce data/lote-2026-02.csv con 6.001 filas y 106 problemas repartidos en
siete clases: 105 que se ven fila por fila y uno que solo se ve mirando el lote.
\"\"\""""
assert old in s; s = s.replace(old, new)

old2 = """        # Los 47 problemas sembrados, repartidos y de siete clases distintas."""
new2 = """        # Los problemas sembrados: siete clases, quince casos de cada una
        # repartidos por todo el archivo. El documento vacío y el no numérico
        # fallan por la misma regla, así que esa clase suma treinta."""
assert old2 in s; s = s.replace(old2, new2)

old3 = """- [ ] **Medición:** cuántos problemas encontró, de cuántas clases, y cuánto tardó sobre las 6.000
      filas. Esos números van en el mensaje del tag."""
new3 = """- [ ] **Medición:** cuántos problemas encontró, de cuántas clases, y cuánto tardó sobre las 6.001
      filas. Esos números van en el mensaje del tag. *(Para que puedas comprobarte: el archivo
      trae 106 problemas de siete clases. Si tu validador encuentra menos, te falta una regla; si
      encuentra más, alguna regla está de más.)*"""
assert old3 in s; s = s.replace(old3, new3)

old4 = """- El generador `generar_lote_febrero.py` siembra **47 problemas de siete clases**, y el número
  está escrito en su docstring. Si alguna fase posterior cambia el generador, ese número hay que
  recalcularlo o el enunciado pasa a mentir."""
new4 = """- El generador `generar_lote_febrero.py` siembra **106 problemas de siete clases** —105 de fila
  más el duplicado—, verificado al escribir la fase, y el número está en su docstring y en los
  criterios de aceptación. Si alguna fase posterior cambia el generador, ese número hay que
  recalcularlo en los tres sitios o el enunciado pasa a mentir."""
assert old4 in s; s = s.replace(old4, new4)
io.open(p,"w",encoding="utf-8").write(s); print("ok")
PYEOF
mkdir -p src/04-errores-y-recursos && cd /tmp/claude-501/f04 && python3 -c "
import re,pathlib
doc=pathlib.Path('/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/04-errores-y-recursos.md').read_text()
gen=[b for b in re.findall(r'\`\`\`python\n(.*?)\`\`\`',doc,re.S) if b.startswith('\"\"\"Genera el lote de febrero')][0]
pathlib.Path('generar_lote_febrero.py').write_text(gen)" && /opt/homebrew/bin/python3.14 generar_lote_febrero.py && cp generar_lote_febrero.py /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/04-errores-y-recursos/

# --- 2026-09-13T02:09:39 · Build the signing binary simulator
mkdir -p /tmp/claude-501/f05 && cd /tmp/claude-501/f05 && cat > firmador_simulado.py <<'PYEOF'
"""Simulador del binario firmador del proveedor tecnológico de Áurea.

Esto NO es código de ejemplo a imitar: imita a un programa ajeno, con sus
rarezas reales, para que el miniproyecto de la Fase 05 se pueda hacer sin
tener el binario del proveedor.

Uso:
    python firmador_simulado.py --entrada <archivo.xml> --salida <archivo.xml>
    python firmador_simulado.py --lote <archivo1.xml> <archivo2.xml> ...

Rarezas que imita, todas tomadas de programas de firma reales:
  · escribe parte de sus mensajes en stdout y parte en stderr, sin criterio
  · un "éxito con advertencias" que devuelve código 3, no 0
  · se cuelga con los NIT que terminan en 7 (simula el timeout del servicio)
  · devuelve código 2 para el certificado vencido y 9 para el XML mal formado
  · tarda entre 40 y 120 ms por factura, como el de verdad
"""

import random
import sys
import time
from pathlib import Path


def sign_one(source: Path, target: Path) -> int:
    """Firma un archivo. Devuelve el código de salida del proveedor."""
    if not source.exists():
        print(f"ERR-404 archivo no encontrado: {source}", file=sys.stderr)
        return 9

    content = source.read_text(encoding="utf-8", errors="replace")
    nit = "".join(ch for ch in content if ch.isdigit())[:9] or "000000000"

    # Se cuelga con los NIT terminados en 7. El de verdad se colgaba cuando el
    # servicio de sellado del proveedor no respondía, que era imposible de predecir.
    if nit.endswith("7"):
        print("conectando con el servicio de sellado...", flush=True)
        time.sleep(3600)

    # Certificado vencido: código 2, y el mensaje va a stdout (no a stderr).
    if nit.endswith("3"):
        print(f"ERR-CERT certificado del emisor vencido (NIT {nit})")
        return 2

    time.sleep(random.uniform(0.04, 0.12))
    target.write_text(f"<!-- firmado {nit} -->\n{content}", encoding="utf-8")

    # Éxito con advertencia: código 3. Está firmado, y el que no mire el
    # código de retorno con cuidado va a creer que falló.
    if nit.endswith("5"):
        print(f"WARN-011 firmado con certificado próximo a vencer (NIT {nit})",
              file=sys.stderr)
        return 3

    print(f"OK firmado {target.name}")
    return 0


def main(argv: list[str]) -> int:
    random.seed(2026)
    if len(argv) >= 5 and argv[1] == "--entrada" and argv[3] == "--salida":
        return sign_one(Path(argv[2]), Path(argv[4]))

    if len(argv) >= 3 and argv[1] == "--lote":
        worst = 0
        for raw in argv[2:]:
            source = Path(raw)
            code = sign_one(source, source.with_suffix(".firmado.xml"))
            worst = max(worst, code)
        return worst

    print("uso: firmador --entrada <xml> --salida <xml>", file=sys.stderr)
    print("     firmador --lote <xml> [<xml> ...]", file=sys.stderr)
    return 64


if __name__ == "__main__":
    sys.exit(main(sys.argv))
PYEOF
mkdir -p facturas && /opt/homebrew/bin/python3.14 - <<'EOF'
from pathlib import Path
import random
random.seed(2026)
Path("facturas").mkdir(exist_ok=True)
for i in range(200):
    nit = str(random.randint(100_000_000, 999_999_999))
    Path(f"facturas/fac-{i:04d}.xml").write_text(
        f"<factura><nit>{nit}</nit><valor>{random.randint(50000,900000)}</valor></factura>\n",
        encoding="utf-8")
print("200 facturas generadas")
EOF
/opt/homebrew/bin/python3.14 firmador_simulado.py --entrada facturas/fac-0000.xml --salida /tmp/out.xml; echo "código: $?"

# --- 2026-09-13T02:09:52 · Measure process-per-invoice vs batch
cd /tmp/claude-501/f05 && cat > medir_procesos.py <<'PYEOF'
"""Una invocación por factura contra una por lote, sobre las 200 facturas del mes."""
import statistics, subprocess, sys, time
from pathlib import Path

PY = sys.executable
FIRMADOR = "firmador_simulado.py"
# Se excluyen los NIT que cuelgan y los que fallan: se miden aparte en la fase.
files = []
for p in sorted(Path("facturas").glob("fac-*.xml")):
    nit = "".join(c for c in p.read_text() if c.isdigit())[:9]
    if not nit.endswith(("7", "3")):
        files.append(p)
print(f"facturas medibles: {len(files)}")

def one_by_one(paths):
    for p in paths:
        subprocess.run([PY, FIRMADOR, "--entrada", str(p), "--salida", str(p.with_suffix(".f.xml"))],
                       capture_output=True, timeout=30)

def one_batch(paths):
    subprocess.run([PY, FIRMADOR, "--lote", *[str(p) for p in paths]],
                   capture_output=True, timeout=300)

def bench(fn, paths, reps=3):
    xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(paths); xs.append(time.perf_counter()-t0)
    xs.sort(); return statistics.median(xs)

# Costo puro de crear un proceso, sin trabajo adentro
xs=[]
for _ in range(30):
    t0=time.perf_counter(); subprocess.run([PY, "-c", "pass"], capture_output=True); xs.append((time.perf_counter()-t0)*1000)
xs.sort()
print(f"crear un proceso de Python (sin trabajo): mediana {statistics.median(xs):.0f} ms")

for n in (10, 50, len(files)):
    sub = files[:n]
    a, b = bench(one_by_one, sub), bench(one_batch, sub)
    print(f"n={n:>3}  una por factura {a*1000:8.0f} ms   una por lote {b*1000:8.0f} ms   "
          f"sobrecosto {(a-b)*1000:7.0f} ms ({(a/b):.1f}×)")
PYEOF
/opt/homebrew/bin/python3.14 medir_procesos.py

# --- 2026-09-13T02:12:09 · Fix simulator determinism and re-measure
cd /tmp/claude-501/f05 && python3 - <<'PYEOF'
import io
p="firmador_simulado.py"; s=io.open(p,encoding="utf-8").read()
s = s.replace("""    time.sleep(random.uniform(0.04, 0.12))""",
"""    # El tiempo depende de la factura y no del proceso: así el resultado es el
    # mismo se invoque una vez por factura o una vez por lote, que es lo que
    # hace que la medición de la fase compare lo que dice comparar.
    random.seed(int(nit))
    time.sleep(random.uniform(0.04, 0.12))""")
s = s.replace("""def main(argv: list[str]) -> int:
    random.seed(2026)
""", """def main(argv: list[str]) -> int:
""")
io.open(p,"w",encoding="utf-8").write(s); print("ok")
PYEOF
/opt/homebrew/bin/python3.14 medir_procesos.py

# --- 2026-09-13T02:18:07 · Clean outputs and re-measure correctly
cd /tmp/claude-501/f05 && rm -f facturas/*.f.xml facturas/*.firmado.xml && ls facturas | wc -l && sed -i '' 's|Path("facturas").glob("fac-\*.xml")|sorted(p for p in Path("facturas").glob("fac-????.xml"))|' medir_procesos.py && /opt/homebrew/bin/python3.14 medir_procesos.py && rm -f facturas/*.f.xml facturas/*.firmado.xml

# --- 2026-09-13T02:20:40 · Verify the simulator's three odd behaviours
cd /tmp/claude-501/f05 && /opt/homebrew/bin/python3.14 - <<'EOF'
import subprocess, sys, time
from pathlib import Path
PY = sys.executable
# busca una factura que cuelgue (NIT terminado en 7) y una con certificado vencido (en 3)
casos = {}
for p in sorted(Path("facturas").glob("fac-????.xml")):
    nit = "".join(c for c in p.read_text() if c.isdigit())[:9]
    casos.setdefault(nit[-1], p)
for d in ("7", "3", "5"):
    p = casos.get(d)
    if not p: continue
    t0=time.perf_counter()
    try:
        r = subprocess.run([PY, "firmador_simulado.py", "--entrada", str(p), "--salida", "/tmp/o.xml"],
                           capture_output=True, text=True, timeout=2)
        print(f"NIT...{d}: código={r.returncode} stdout={r.stdout.strip()!r} stderr={r.stderr.strip()!r}")
    except subprocess.TimeoutExpired:
        print(f"NIT...{d}: TIMEOUT a los {time.perf_counter()-t0:.1f}s (el proceso se colgó)")
EOF

# --- 2026-09-13T02:25:30 · Count each outcome class in the invoice set
cd /tmp/claude-501/f05 && /opt/homebrew/bin/python3.14 -c "
from pathlib import Path
from collections import Counter
c=Counter()
for p in sorted(Path('facturas').glob('fac-????.xml')):
    nit=''.join(ch for ch in p.read_text() if ch.isdigit())[:9]
    d=nit[-1]
    c['cuelga (7)' if d=='7' else 'falla cert (3)' if d=='3' else 'advertencia (5)' if d=='5' else 'ok']+=1
print(dict(c), 'total', sum(c.values()))"

# --- 2026-09-13T02:25:49 · Fix counts and save F05 assets
cd cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p="05-shell-con-esteroides.md"; s=io.open(p,encoding="utf-8").read()

old = """19. **Medición.** Cronometra el lote completo con timeouts de 2, 5 y 30 segundos. Las facturas
    colgadas son 34: calcula el tiempo perdido en cada caso y decide qué timeout dejarías, sabiendo
    que un firmado legítimo tarda 120 ms como máximo."""
new = """19. **Medición.** Cronometra el lote completo con timeouts de 2, 5 y 30 segundos. Las facturas
    que se cuelgan son 20: calcula el tiempo perdido en cada caso y decide qué timeout dejarías,
    sabiendo que un firmado legítimo tarda 120 ms como máximo."""
assert old in s; s = s.replace(old, new)

old2 = """- [ ] **Medición:** tiempo total del lote, y cuántos segundos se fueron en las facturas colgadas.
      Esos dos números van en el mensaje del tag."""
new2 = """- [ ] **Medición:** tiempo total del lote, y cuántos segundos se fueron en las facturas colgadas.
      Esos dos números van en el mensaje del tag. *(Para que puedas comprobarte: de las 200
      facturas, **143 se firman limpias, 23 devuelven advertencia, 14 fallan por certificado
      vencido y 20 se cuelgan**. Si tus cuatro números no suman eso, algo está clasificando mal —
      y lo más probable es que sean las 23 de advertencia contadas como fallos.)*"""
assert old2 in s; s = s.replace(old2, new2)

old3 = """se descartó por una razón que se puede defender con el número de la medición: **cada cuelgue cuesta
el timeout completo**, así que reintentar un cuelgue con 5 segundos de timeout convierte 34
facturas colgadas en 340 segundos perdidos en vez de 170."""
new3 = """se descartó por una razón que se puede defender con el número de la medición: **cada cuelgue cuesta
el timeout completo**, así que reintentar un cuelgue con 5 segundos de timeout convierte 20
facturas colgadas en 200 segundos perdidos en vez de 100."""
if old3 in s:
    s = s.replace(old3, new3)
else:
    # el texto real difiere ligeramente; localizar y corregir el número
    s = s.replace("convierte 34\nfacturas colgadas en 340 segundos perdidos en vez de 170.",
                  "convierte 20\nfacturas colgadas en 200 segundos perdidos en vez de 100.")
io.open(p,"w",encoding="utf-8").write(s)
print("34 restante:", s.count("34 facturas"), "| 20 facturas:", s.count("20 facturas"))
PYEOF
mkdir -p src/05-shell-con-esteroides && cp /tmp/claude-501/f05/firmador_simulado.py src/05-shell-con-esteroides/ && cd /tmp/claude-501/f05 && python3 -c "
import re,pathlib
doc=pathlib.Path('/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/05-shell-con-esteroides.md').read_text()
gen=[b for b in re.findall(r'\`\`\`python\n(.*?)\`\`\`',doc,re.S) if b.startswith('\"\"\"Genera las 200 facturas')][0]
pathlib.Path('generar_facturas.py').write_text(gen)" && /opt/homebrew/bin/python3.14 generar_facturas.py && cp generar_facturas.py /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/05-shell-con-esteroides/

# --- 2026-09-13T02:25:57 · Find remaining wrong counts
cd cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "34\b" 05-shell-con-esteroides.md

# --- 2026-09-13T02:26:01 · Check the reference solution numbers
cd cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "segundos perdidos" 05-shell-con-esteroides.md

# --- 2026-09-13T02:26:05 · Check reference solution numbers
grep -n "segundos perdidos\|facturas colgadas en" /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/05-shell-con-esteroides.md

# --- 2026-09-13T02:26:32 · Generate dirty exports for F06
mkdir -p /tmp/claude-501/f06 && cd /tmp/claude-501/f06 && cp /tmp/claude-501/f02/bench.py . && cat > generar_exports_sucios.py <<'PYEOF'
"""Genera los exports del cierre de mes de las diez sedes, cada uno con su suciedad.

Uso:  python generar_exports_sucios.py
Produce data/cierre/ con seis formatos distintos, como llegan de verdad.
"""

import csv
import random
from pathlib import Path

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]
CODES = {"D8010": 180000, "D8020": 95000, "D2740": 890000,
         "D7140": 210000, "D1110": 75000, "D8670": 120000}
DESCRIPTIONS = {
    "D8010": "Control de ortodoncia, arco superior",
    "D8020": "Cambio de ligaduras",
    "D2740": 'Corona en zirconio, cara vestibular, tono A2',
    "D7140": "Exodoncia simple",
    "D1110": "Profilaxis",
    "D8670": 'Retenedor fijo 3x3, "tipo Hawley"',
}
FIRST = ["Ana María", "Carlos Efrén", "Luz Dary", "Jhon Fredy", "Diana Marcela",
         "Óscar Iván", "Yenny Paola", "Wílmer Andrés", "Sandra Milena", "José Ángel"]
LAST = ["Robledo", "Neira", "Peña", "Chaparro", "Ocampo", "Guzmán", "Rojas",
        "Buitrago", "Cárdenas", "Quintero", "Mahecha", "Bermúdez"]


def rows_for(branch, count, rng):
    for _ in range(count):
        code = rng.choice(list(CODES))
        yield {
            "documento": str(rng.randint(10_000_000, 1_299_999_999)),
            "paciente": f"{rng.choice(LAST)}, {rng.choice(FIRST)}",   # ← coma dentro de celda
            "sede": branch,
            "fecha": f"2026-03-{rng.randint(1, 31):02d}",
            "codigo": code,
            "descripcion": DESCRIPTIONS[code],
            "valor": str(CODES[code]),
        }


FIELDS = ["documento", "paciente", "sede", "fecha", "codigo", "descripcion", "valor"]


def main():
    rng = random.Random(2026)
    out = Path("data/cierre")
    out.mkdir(parents=True, exist_ok=True)

    for index, branch in enumerate(BRANCHES):
        rows = list(rows_for(branch, rng.randint(550, 700), rng))
        path = out / f"{branch.lower()}.csv"

        if index < 6:
            # Las seis sedes con Odontovía: latin-1, separado por punto y coma.
            with path.open("w", encoding="latin-1", newline="") as f:
                w = csv.DictWriter(f, FIELDS, delimiter=";")
                w.writeheader(); w.writerows(rows)
        elif index == 6:
            # La que exporta desde Excel: UTF-8 con BOM.
            with path.open("w", encoding="utf-8-sig", newline="") as f:
                w = csv.DictWriter(f, FIELDS); w.writeheader(); w.writerows(rows)
        elif index == 7:
            # El otro software: columnas en otro orden.
            order = ["fecha", "sede", "documento", "valor", "codigo", "paciente", "descripcion"]
            with path.open("w", encoding="utf-8", newline="") as f:
                w = csv.DictWriter(f, order); w.writeheader(); w.writerows(rows)
        elif index == 8:
            # El Google Sheet: notas dentro de la celda de valor.
            for row in rows[::37]:
                row["valor"] = f"{row['valor']} (pendiente confirmar)"
            with path.open("w", encoding="utf-8", newline="") as f:
                w = csv.DictWriter(f, FIELDS); w.writeheader(); w.writerows(rows)
        else:
            # Zipaquirá: el cuaderno transcrito, con separador de miles y tabulaciones.
            for row in rows:
                row["valor"] = f"{int(row['valor']):,}".replace(",", ".")
            with path.open("w", encoding="utf-8", newline="") as f:
                w = csv.DictWriter(f, FIELDS, delimiter="\t")
                w.writeheader(); w.writerows(rows)

        print(f"{path}: {len(rows)} filas")


if __name__ == "__main__":
    main()
PYEOF
/opt/homebrew/bin/python3.14 generar_exports_sucios.py && echo "--- muestra latin-1 ---" && head -2 data/cierre/centro.csv && echo "--- muestra BOM ---" && head -2 data/cierre/fontibon.csv | cat -v | cut -c1-90

# --- 2026-09-13T02:26:53 · Measure CSV rescan vs SQLite index
cd /tmp/claude-501/f06 && cat > medir_historico.py <<'PYEOF'
"""Consultar el histórico releyendo los CSV contra tenerlo en sqlite3 con índice."""
import csv, random, sqlite3, statistics, time
from pathlib import Path
import sys
sys.path.insert(0, ".")
from bench import measure, render

HIST = Path("data/historico")
HIST.mkdir(parents=True, exist_ok=True)
rng = random.Random(7)

def build_months(months):
    """Un CSV por sede y mes, como los guarda hoy Patricia."""
    for f in HIST.glob("*.csv"): f.unlink()
    rows_total = 0
    for m in range(months):
        for branch in ("centro","chapinero","suba","kennedy","usaquen",
                       "engativa","fontibon","restrepo","soacha","zipaquira"):
            p = HIST / f"{branch}-2025-{m%12+1:02d}.csv"
            with p.open("a", encoding="utf-8", newline="") as f:
                w = csv.writer(f)
                if p.stat().st_size == 0: w.writerow(["documento","codigo","fecha","valor"])
                for _ in range(600):
                    w.writerow([rng.randint(10_000_000,1_299_999_999),
                                rng.choice(["D8010","D8020","D2740","D7140"]),
                                f"2025-{m%12+1:02d}-{rng.randint(1,28):02d}",
                                rng.choice([75000,95000,180000,890000])])
                    rows_total += 1
    return rows_total

def build_sqlite(db_path):
    if db_path.exists(): db_path.unlink()
    con = sqlite3.connect(db_path)
    con.execute("CREATE TABLE billed (document TEXT, code TEXT, date TEXT, amount INTEGER)")
    for p in sorted(HIST.glob("*.csv")):
        with p.open(encoding="utf-8", newline="") as f:
            reader = csv.reader(f); next(reader)
            con.executemany("INSERT INTO billed VALUES (?,?,?,?)", reader)
    con.execute("CREATE INDEX idx_billed ON billed(document, code, date)")
    con.commit()
    return con

def scan_csv(queries):
    found = 0
    wanted = set(queries)
    for p in sorted(HIST.glob("*.csv")):
        with p.open(encoding="utf-8", newline="") as f:
            reader = csv.reader(f); next(reader)
            for r in reader:
                if (r[0], r[1], r[2]) in wanted: found += 1
    return found

def query_sqlite(con, queries):
    found = 0
    for q in queries:
        if con.execute("SELECT 1 FROM billed WHERE document=? AND code=? AND date=? LIMIT 1", q).fetchone():
            found += 1
    return found

for months in (1, 6, 24):
    rows = build_months(months)
    db = Path("data/historico.sqlite3")
    con = build_sqlite(db)
    sample = [tuple(map(str, r)) for r in con.execute(
        "SELECT document, code, date FROM billed ORDER BY RANDOM() LIMIT 50")]
    csv_bytes = sum(p.stat().st_size for p in HIST.glob("*.csv"))
    a = measure("csv", lambda: scan_csv(sample), 3)
    b = measure("sqlite", lambda: query_sqlite(con, sample), 3)
    print(f"{months:>2} meses · {rows:>7,} filas · CSV {csv_bytes/1e6:5.1f} MB · db {db.stat().st_size/1e6:5.1f} MB"
          f" || releer CSV {a['mediana_ms']:8.1f} ms (pico {a['pico_mb']:.1f} MB)"
          f" · sqlite {b['mediana_ms']:7.2f} ms (pico {b['pico_mb']:.2f} MB)")
    con.close()
PYEOF
/opt/homebrew/bin/python3.14 medir_historico.py

# --- 2026-09-13T02:31:59 · Verify F06 generator and the debt payoff
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p="06-formatos-en-la-caja.md"; s=io.open(p,encoding="utf-8").read()
old = """Aquí el costo no es cero y ya lo viste en la Fase 07 —perdón, la vas a ver: cada dependencia es
algo que se resuelve, que se instala, que puede romperse, y que **Patricia va a tener que tener en
su portátil**. Y la mitad de las veces, la respuesta ya viene en la caja."""
new = """Aquí el costo no es cero, y la Fase 07 lo va a medir: cada dependencia es algo que se resuelve,
que se instala, que puede romperse, y que **Patricia va a tener que tener en su portátil**. Y la
mitad de las veces, la respuesta ya viene en la caja."""
assert old in s; io.open(p,"w",encoding="utf-8").write(s.replace(old,new)); print("ok")
PYEOF
mkdir -p src/06-formatos-en-la-caja && cd /tmp/claude-501/f06 && python3 -c "
import re,pathlib
doc=pathlib.Path('/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/06-formatos-en-la-caja.md').read_text()
gen=[b for b in re.findall(r'\`\`\`python\n(.*?)\`\`\`',doc,re.S) if b.startswith('\"\"\"Genera los exports del cierre')][0]
pathlib.Path('gen_doc.py').write_text(gen)" && rm -rf data/cierre && /opt/homebrew/bin/python3.14 gen_doc.py | tail -3 && /opt/homebrew/bin/python3.14 -c "
import csv
# comprueba que csv lee bien lo que split rompe
with open('data/cierre/centro.csv', encoding='latin-1', newline='') as f:
    r = list(csv.DictReader(f, delimiter=';'))
print('filas leídas con csv:', len(r))
print('ejemplo paciente:', repr(r[0]['paciente']))
total_csv = sum(int(x['valor']) for x in r)
# y ahora el split de la Fase 01
total_split = 0; rotas = 0
with open('data/cierre/centro.csv', encoding='latin-1') as f:
    next(f)
    for line in f:
        parts = line.strip().split(';')
        try: total_split += int(parts[6])
        except (IndexError, ValueError): rotas += 1
print(f'total con csv: {total_csv:,} | total con split: {total_split:,} | filas que el split no pudo: {rotas}')
"

# --- 2026-09-13T02:32:15 · Find where the split actually breaks
cd /tmp/claude-501/f06 && /opt/homebrew/bin/python3.14 -c "
import csv
for name, enc in [('fontibon','utf-8-sig'), ('restrepo','utf-8'), ('soacha','utf-8')]:
    p=f'data/cierre/{name}.csv'
    with open(p, encoding=enc, newline='') as f:
        rows=list(csv.DictReader(f))
    total_csv=sum(int(str(r['valor']).split()[0]) for r in rows)
    # el split de la Fase 01, sobre un archivo separado por comas
    total_split=0; rotas=0
    with open(p, encoding=enc) as f:
        next(f)
        for line in f:
            parts=line.strip().split(',')
            try: total_split+=int(parts[6])
            except (IndexError, ValueError): rotas+=1
    print(f'{name:10s} filas={len(rows):4d} csv={total_csv:>12,} split={total_split:>12,} rotas={rotas}')
"

# --- 2026-09-13T02:32:40 · Reproduce exactly what the F01 split does with commas
cd /tmp/claude-501/f06 && /opt/homebrew/bin/python3.14 - <<'EOF'
import csv
from decimal import Decimal
from pathlib import Path

# Archivo en el formato de la Fase 01 (6 columnas, coma), con tres nombres que traen coma.
rows = [
    ("1019283746", "Ana María Robledo", "Centro", "2026-03-04", "D8010", "180000"),
    ("52847193", "Cárdenas, Carlos Efrén", "Centro", "2026-03-04", "D2740", "890000"),
    ("79541226", "Luz Dary Peña", "Centro", "2026-03-19", "D8010", "180000"),
    ("1090957655", "Neira, Yenny Paola", "Centro", "2026-03-22", "D8020", "95000"),
]
p = Path("f01_con_comas.csv")
with p.open("w", encoding="utf-8", newline="") as f:
    w = csv.writer(f); w.writerow(["documento","paciente","sede","fecha","codigo","valor"]); w.writerows(rows)
print(p.read_text(encoding="utf-8"))

# El read_rows + summarize de la Fase 01, literal
def read_rows_f01(path):
    with open(path, encoding="utf-8") as file:
        next(file)
        for line in file:
            line = line.strip()
            if line: yield tuple(line.split(","))

def summarize_f01(rs):
    total = Decimal("0"); pacientes=set(); por_sede={}
    for r in rs:
        try: amount = Decimal(r[5])
        except Exception as e: 
            print(f"  ⚠️  revienta en la fila de {r[1]!r}: {type(e).__name__}")
            continue
        total += amount; pacientes.add(r[0]); por_sede[r[2]] = por_sede.get(r[2],0)+1
    return total, len(pacientes), por_sede

print("--- con el split de la Fase 01 ---")
t, n, sedes = summarize_f01(read_rows_f01(p))
print(f"  total: ${t:,} · pacientes: {n} · por sede: {sedes}")
print("--- con csv ---")
with p.open(encoding="utf-8", newline="") as f:
    rr = list(csv.DictReader(f))
print(f"  total: ${sum(Decimal(r['valor']) for r in rr):,} · pacientes: {len({r['documento'] for r in rr})}"
      f" · por sede: {{'Centro': {len(rr)}}}")
EOF

# --- 2026-09-13T02:33:10 · Correct the debt story with verified numbers
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p="06-formatos-en-la-caja.md"; s=io.open(p,encoding="utf-8").read()

old = """Seis fases atrás, `read_rows` partía las líneas con `split(",")`. Funcionaba, y el docstring decía
en qué fase se iba a arreglar. Hoy llega el archivo de la sede Centro con un paciente que se llama
`Cárdenas, Carlos Efrén` y el script produce basura sin lanzar una sola excepción. Esa factura se
paga hoy, y se lee con un `git diff`."""
new = """Seis fases atrás, `read_rows` partía las líneas con `split(",")`. Funcionaba, y el docstring decía
en qué fase se iba a arreglar. Hoy llega el archivo con un paciente que se llama
`Cárdenas, Carlos Efrén` y el script se cae — y si alguien le hubiera puesto un `except` encima
para que no se cayera, habría facturado **$360.000 donde debía facturar $1.345.000**. Esa factura
se paga hoy, con los dos números delante."""
assert old in s; s = s.replace(old, new)

old2 = """**La factura, que es lo que esta fase viene a enseñar:**

```bash
git diff fase-01 fase-06 -- aur_cli.py
```

Léela entera una vez."""
new2 = """**La factura, con números.** Cuatro filas del export, dos de ellas con una coma dentro del nombre
—que es lo que produce cualquier sistema que escriba `apellido, nombre`—:

```text
documento,paciente,sede,fecha,codigo,valor
1019283746,Ana María Robledo,Centro,2026-03-04,D8010,180000
52847193,"Cárdenas, Carlos Efrén",Centro,2026-03-04,D2740,890000
79541226,Luz Dary Peña,Centro,2026-03-19,D8010,180000
1090957655,"Neira, Yenny Paola",Centro,2026-03-22,D8020,95000
```

| | Filas leídas | Pacientes | Total facturado |
|---|---|---|---|
| `split(",")` de la Fase 01 | 2 de 4 | 2 | **$360.000** |
| `csv.DictReader` | 4 de 4 | 4 | **$1.345.000** |

**Y conviene ser preciso sobre cómo falla, porque no es como uno esperaría.** El `split` produce
siete campos donde había seis, así que `row[5]` deja de ser el valor y pasa a ser el código: al
convertirlo, `Decimal("D2740")` levanta `InvalidOperation`. En la Fase 01 no había manejo de
errores, así que **el script muere con su traza en la primera fila con coma** — ruidoso, feo, y
honesto.

El daño silencioso aparece cuando alguien, para que "no se caiga", envuelve eso en un
`except Exception: continue`. Ahí el script sobrevive, salta las dos filas, y reporta
$360.000 con toda tranquilidad: **un 73% menos**, sin una sola advertencia. Es exactamente el
error 1 de la Fase 04, y esta es su factura en pesos.

**Y la factura en código:**

```bash
git diff fase-01 fase-06 -- aur_cli.py
```

Léela entera una vez."""
assert old2 in s; s = s.replace(old2, new2)

old3 = """- [ ] **Medición:** filas consolidadas, total facturado, y cuánto tardó. Además, **el total
      facturado calculado con `split(",")` y con `csv`** sobre el mismo archivo: la diferencia es
      la factura de la deuda 💸, y va en el mensaje del tag."""
new3 = """- [ ] **Medición:** filas consolidadas, total facturado, y cuánto tardó. Además, **cuántas filas
      pierde el `split(",")` de la Fase 01** sobre los exports separados por coma, y cuánto dinero
      son. Ese par de números es la factura de la deuda 💸 y va en el mensaje del tag."""
if old3 in s: s = s.replace(old3, new3)
io.open(p,"w",encoding="utf-8").write(s); print("ok")
PYEOF
mkdir -p src/06-formatos-en-la-caja && cp /tmp/claude-501/f06/gen_doc.py src/06-formatos-en-la-caja/generar_exports_sucios.py && ls -la *.md src/*/ | head -40

# --- 2026-09-13T02:33:20 · Structural check across all phases
for f in 0*.md; do n=$(grep -c '^## ' "$f"); t=$(grep -c 'git tag -a fase-' "$f"); e=$(grep -oE '^## 🧪 8\. Ejercicios \(([0-9]+)\)' "$f" | grep -oE '[0-9]+\)' | tr -d ')'); echo "$f · secciones=$n · tag=$t · ejercicios=${e:-n/a}"; done

# --- 2026-09-13T02:36:44 · Reconstruct end-of-Bloque-A code
mkdir -p /tmp/claude-501/f08 && cd /tmp/claude-501/f08 && cat > aur_cli.py <<'PYEOF'
"""aur — la caja de herramientas de Patricia.

Estado al cerrar el Bloque A (Fase 06): un archivo, stdlib pura, cero dependencias.
"""

import argparse
import csv
import re
import sqlite3
import sys
import tomllib
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from pathlib import Path

VALID_BRANCHES = frozenset({
    "Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
    "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira",
})
NOTE = re.compile(r"\s*\(.*\)\s*$")


class AurError(Exception):
    """Error del dominio de Áurea."""


class InvalidRow(AurError):
    """Una fila que no se puede facturar."""

    def __init__(self, line_number, field, reason):
        self.line_number = line_number
        self.field = field
        self.reason = reason
        super().__init__(f"fila {line_number}, campo '{field}': {reason}")


@dataclass(frozen=True, slots=True)
class Row:
    """Una fila del export, normalizada."""

    document: str
    patient: str
    branch: str
    date: str
    code: str
    description: str
    amount: Decimal


def parse_amount(raw):
    """Convierte el valor a Decimal aceptando las formas de las tres sedes."""
    cleaned = NOTE.sub("", raw).strip()
    if cleaned.count(".") == 1 and len(cleaned.rsplit(".", 1)[1]) == 3:
        cleaned = cleaned.replace(".", "")
    try:
        return Decimal(cleaned)
    except InvalidOperation:
        raise InvalidRow(0, "valor", f"no es un número: {raw!r}") from None


def read_rows(path, encoding="utf-8-sig", delimiter=","):
    """Lee un export y produce filas normalizadas."""
    with path.open(encoding=encoding, newline="") as file:
        for record in csv.DictReader(file, delimiter=delimiter):
            yield Row(
                document=record["documento"].strip(),
                patient=record["paciente"].strip(),
                branch=record["sede"].strip(),
                date=record["fecha"].strip(),
                code=record["codigo"].strip(),
                description=record.get("descripcion", "").strip(),
                amount=parse_amount(record["valor"]),
            )


def summarize(rows):
    """Resumen del mes: procedimientos, pacientes distintos y total."""
    total = Decimal("0")
    patients = set()
    by_code = {}
    count = 0
    for row in rows:
        count += 1
        total += row.amount
        patients.add(row.document)
        by_code[row.code] = by_code.get(row.code, Decimal("0")) + row.amount
    return {
        "procedimientos": count,
        "pacientes": len(patients),
        "total": total,
        "por_codigo": by_code,
    }


def render(summary, path):
    """La salida que ve Patricia."""
    lines = [
        f"Resumen de {path}",
        f"  procedimientos: {summary['procedimientos']}",
        f"  pacientes distintos: {summary['pacientes']}",
        f"  facturado: ${summary['total']:,.0f}",
    ]
    for code, amount in sorted(summary["por_codigo"].items()):
        lines.append(f"    {code}  ${amount:>12,.0f}")
    return "\n".join(lines)


def validate_row(row, line_number):
    """Comprueba una fila."""
    if not row.document.strip().isdigit():
        raise InvalidRow(line_number, "documento", f"no es numérico: {row.document!r}")
    if row.branch not in VALID_BRANCHES:
        raise InvalidRow(line_number, "sede", f"no es una sede de la red: {row.branch!r}")
    if row.amount <= 0:
        raise InvalidRow(line_number, "valor", f"debe ser positivo: {row.amount}")


def validate_batch(rows):
    """Valida el lote completo y levanta un ExceptionGroup con todo lo que falló."""
    problems = []
    for line_number, row in enumerate(rows, start=2):
        try:
            validate_row(row, line_number)
        except AurError as error:
            problems.append(error)
    if problems:
        raise ExceptionGroup(f"{len(problems)} filas no se pueden facturar", problems)


SPECIAL_RULES = {}


def rule_for(partner_id):
    """Registra la regla especial de un aliado."""
    def register(function):
        SPECIAL_RULES[partner_id] = function
        return function
    return register


@rule_for("P004")
def minimum_per_case(value, specialty, month_to_date, rate):
    """Neira cobra un mínimo por caso."""
    return max(value * rate, Decimal("150000"))


@rule_for("P005")
def monthly_cap(value, specialty, month_to_date, rate):
    """Buitrago negoció un tope mensual."""
    return min(value * rate, max(Decimal("2000000") - month_to_date, Decimal("0")))


def load_rates(path=Path("tarifas.toml")):
    """Lee las tarifas del archivo de configuración."""
    with path.open("rb") as file:
        config = tomllib.load(file)
    return {partner: Decimal(str(rate)) for partner, rate in config["aliados"].items()}


def referral_fee(partner_id, value, rates, specialty="", month_to_date=Decimal("0")):
    """La comisión de un caso derivado."""
    rate = rates[partner_id]
    rule = SPECIAL_RULES.get(partner_id)
    return rule(value, specialty, month_to_date, rate) if rule else value * rate


SCHEMA = """
CREATE TABLE IF NOT EXISTS billed (
    document TEXT NOT NULL, code TEXT NOT NULL, date TEXT NOT NULL,
    branch TEXT NOT NULL, amount TEXT NOT NULL, batch TEXT NOT NULL,
    PRIMARY KEY (document, code, date)
);
"""


def open_history(path=Path("data/historico.sqlite3")):
    """Abre el histórico, creándolo si no existe."""
    connection = sqlite3.connect(path)
    connection.executescript(SCHEMA)
    return connection


def already_billed(connection, document, code, date):
    """¿Este procedimiento ya se facturó?"""
    row = connection.execute(
        "SELECT batch FROM billed WHERE document = ? AND code = ? AND date = ?",
        (document, code, date),
    ).fetchone()
    return row is not None


def record_batch(connection, rows, batch):
    """Registra el cierre completo."""
    with connection:
        cursor = connection.executemany(
            "INSERT OR IGNORE INTO billed VALUES (?, ?, ?, ?, ?, ?)",
            ((r.document, r.code, r.date, r.branch, str(r.amount), batch) for r in rows),
        )
        return cursor.rowcount


COMMANDS = {}


def command(name):
    """Registra un comando del CLI."""
    def register(function):
        COMMANDS[name] = function
        return function
    return register


@command("resumen")
def summary_command(args):
    """Resumen del mes de una sede."""
    path = args.datos / f"{args.sede.lower()}-{args.mes}.csv"
    print(render(summarize(read_rows(path)), path))
    return 0


@command("validar")
def validate_command(args):
    """Valida un lote antes de facturar."""
    try:
        validate_batch(read_rows(args.archivo))
    except* InvalidRow as group:
        for error in group.exceptions:
            print(f"  línea {error.line_number}: {error.reason}", file=sys.stderr)
        return 1
    return 0


def build_parser():
    """La interfaz del CLI."""
    parser = argparse.ArgumentParser(prog="aur", description="Cierre de mes de la red Áurea.")
    commands = parser.add_subparsers(dest="command", required=True)

    summary = commands.add_parser("resumen")
    summary.add_argument("--sede", required=True, choices=sorted(VALID_BRANCHES))
    summary.add_argument("--mes", required=True)
    summary.add_argument("--datos", type=Path, default=Path("data"))

    validate = commands.add_parser("validar")
    validate.add_argument("archivo", type=Path)
    return parser


if __name__ == "__main__":
    parsed = build_parser().parse_args()
    sys.exit(COMMANDS[parsed.command](parsed))
PYEOF
wc -l aur_cli.py && /opt/homebrew/bin/python3.14 -c "import ast,sys; ast.parse(open('aur_cli.py').read()); print('sintaxis OK')"

# --- 2026-09-13T02:36:51 · Install mypy
cd /tmp/claude-501/f08 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python mypy==2.3.1 2>&1 | tail -2; ./.venv/bin/mypy --version 2>/dev/null || /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python mypy 2>&1 | tail -3; ./.venv/bin/mypy --version

# --- 2026-09-13T02:37:01 · Run mypy strict on Bloque A code
cd /tmp/claude-501/f08 && ./.venv/bin/mypy --strict aur_cli.py 2>&1 | tail -40 && echo "=== conteo por código de error ===" && ./.venv/bin/mypy --strict aur_cli.py 2>&1 | grep -oE '\[[a-z-]+\]$' | sort | uniq -c | sort -rn

# --- 2026-09-13T02:37:17 · Verify the return-in-except-star error
cd /tmp/claude-501/f08 && /opt/homebrew/bin/python3.14 -c "
src = '''
def f():
    try:
        pass
    except* ValueError as g:
        return 1
'''
try:
    compile(src, '<test>', 'exec')
    print('compila')
except SyntaxError as e:
    print('SyntaxError:', e.msg)
" && echo "--- ¿y el acceso a los atributos del subgrupo? ---" && /opt/homebrew/bin/python3.14 -c "
class E(Exception):
    def __init__(s, n): s.n=n; super().__init__(str(n))
try:
    raise ExceptionGroup('x', [E(1), E(2)])
except* E as g:
    print('tipo de g:', type(g).__name__)
    print('g.exceptions:', [type(e).__name__ for e in g.exceptions])
    print('acceso directo g.n:', getattr(g, 'n', 'NO EXISTE'))
"

# --- 2026-09-13T02:37:36 · Verify Hypothesis finds the float bug
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

# --- 2026-09-13T02:42:27 · Read detailed scope of phases 10-12
sed -n '552,700p' prompts/propuesta-fases-y-alcance.md

# --- 2026-09-13T02:42:29 · Read Bloque C detailed scope
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -n '558,700p' prompts/propuesta-fases-y-alcance.md

# --- 2026-09-13T02:42:37 · Set up FastAPI environment
mkdir -p /tmp/claude-501/f10 && cd /tmp/claude-501/f10 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python fastapi==0.141.1 uvicorn==0.52.4 pydantic==2.13.5 httpx==0.28.1 && ./.venv/bin/python -c "import fastapi, pydantic, uvicorn; print('fastapi', fastapi.__version__, '· pydantic', pydantic.VERSION, '· uvicorn', uvicorn.__version__)"

# --- 2026-09-13T02:43:01 · Build and smoke-test the API
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

# --- 2026-09-13T02:43:19 · Measure endpoint latency and validation cost
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

# --- 2026-09-13T02:43:37 · Measure over real HTTP with uvicorn
cd /tmp/claude-501/f10 && (./.venv/bin/uvicorn app:app --port 8765 --log-level error &) && sleep 3 && ./.venv/bin/python - <<'EOF'
import httpx, statistics, time
base="http://127.0.0.1:8765"
def bench(fn, reps=300):
    for _ in range(30): fn()
    xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(); xs.append((time.perf_counter()-t0)*1000)
    xs.sort(); return statistics.median(xs), xs[int(len(xs)*0.95)-1]
with httpx.Client(base_url=base) as c:
    for name, fn in [
        ("GET /availability", lambda: c.get("/availability", params={"branch":"centro","day":"2026-10-15"})),
        ("GET /availability-raw", lambda: c.get("/availability-raw", params={"branch":"centro","day":"2026-10-15"})),
        ("POST /bookings", lambda: c.post("/bookings", json={"patient_document":"1019283746","branch":"centro","phase":"orthodontic","starts_at":"2026-10-15T15:40:00-05:00"})),
        ("POST /bookings inválido (422)", lambda: c.post("/bookings", json={"patient_document":"AB1","branch":"centro","phase":"orthodontic","starts_at":"2026-10-15T15:40:00-05:00"})),
    ]:
        m,p=bench(fn); print(f"{name:32s} mediana {m:6.2f} ms   p95 {p:6.2f} ms")
EOF
pkill -f "uvicorn app:app" ; echo "servidor detenido"

# --- 2026-09-13T02:48:33 · Check for Postgres availability
which docker podman postgres psql pg_ctl 2>/dev/null; echo "---"; docker info 2>&1 | head -3

# --- 2026-09-13T02:48:39 · Check if a local Postgres is running
export PATH=/opt/homebrew/opt/postgresql@18/bin:$PATH; pg_isready 2>&1; psql -l 2>&1 | head -5

# --- 2026-09-13T02:48:48 · Start a temporary Postgres instance
export PATH=/opt/homebrew/opt/postgresql@18/bin:$PATH; PGD=/tmp/claude-501/pgdata; rm -rf $PGD; initdb -D $PGD -U aurea --auth=trust >/dev/null 2>&1 && pg_ctl -D $PGD -o "-p 55432 -k /tmp/claude-501" -l /tmp/claude-501/pg.log start >/dev/null 2>&1; sleep 2; pg_isready -h /tmp/claude-501 -p 55432 && createdb -h /tmp/claude-501 -p 55432 -U aurea agenda && psql -h /tmp/claude-501 -p 55432 -U aurea -d agenda -c "select version();" | head -3

# --- 2026-09-13T02:49:00 · Install SQLAlchemy and psycopg
mkdir -p /tmp/claude-501/f11 && cd /tmp/claude-501/f11 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python 'sqlalchemy==2.0.52' 'psycopg[binary]==3.3.5' 'alembic==1.20.0' && ./.venv/bin/python -c "import sqlalchemy, psycopg; print('sqlalchemy', sqlalchemy.__version__, '· psycopg', psycopg.__version__)"

# --- 2026-09-13T02:49:29 · Seed Postgres with the Aurea domain
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

# --- 2026-09-13T02:49:54 · Measure raw SQL vs Core vs ORM and the N+1
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

# --- 2026-09-13T02:50:15 · Measure the naive vs single-query plan report
cd /tmp/claude-501/f11 && ./.venv/bin/python - <<'EOF'
import statistics, time, psycopg
DSN="host=/tmp/claude-501 port=55432 user=aurea dbname=agenda"
con = psycopg.connect(DSN)

# La pregunta: ¿qué planes llevan más de 90 días quietos en la fase periodontal?
GOOD = """
SELECT p.id, ph.last_moved_on
FROM treatment_plans p
JOIN plan_phases ph ON ph.plan_id = p.id
WHERE ph.kind = 'periodontal' AND ph.status = 'in_progress'
  AND ph.last_moved_on < current_date - interval '90 days'
ORDER BY ph.last_moved_on
"""
def good():
    with con.cursor() as c:
        c.execute(GOOD); return c.fetchall()

def naive():
    """El modelo obvio: traer los planes y preguntar por cada uno."""
    with con.cursor() as c:
        c.execute("SELECT id FROM treatment_plans")
        plans=[r[0] for r in c.fetchall()]
        out=[]
        for pid in plans:
            c.execute("""SELECT last_moved_on FROM plan_phases
                         WHERE plan_id=%s AND kind='periodontal' AND status='in_progress'
                           AND last_moved_on < current_date - interval '90 days'""", (pid,))
            r=c.fetchone()
            if r: out.append((pid, r[0]))
        return out

def bench(fn, reps=15):
    fn(); xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); r=fn(); xs.append((time.perf_counter()-t0)*1000)
    xs.sort(); return statistics.median(xs), len(r)

a,na = bench(naive, 5); b,nb = bench(good)
print(f"una consulta por plan (701 consultas): {a:8.1f} ms · {na} planes")
print(f"una sola consulta con JOIN:            {b:8.2f} ms · {nb} planes")
print(f"relación: {a/b:.0f}×")
with con.cursor() as c:
    c.execute("EXPLAIN (ANALYZE, BUFFERS) " + GOOD)
    for row in c.fetchall()[:4]: print("   ", row[0])
EOF

# --- 2026-09-13T02:55:15 · Install Django
mkdir -p /tmp/claude-501/f12 && cd /tmp/claude-501/f12 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python 'django==6.1.1' 'psycopg[binary]==3.3.5' && ./.venv/bin/python -c "import django; print('django', django.get_version())"

# --- 2026-09-13T02:55:39 · Build the Django back-office
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

# --- 2026-09-13T02:55:47 · Inspect settings
cd /tmp/claude-501/f12 && grep -n "INSTALLED_APPS" -A 10 consultorio/settings.py | head -14

# --- 2026-09-13T02:55:53 · Run migrations and count Django lines
cd /tmp/claude-501/f12 && sed -i '' "s/    'django.contrib.staticfiles',/    'django.contrib.staticfiles',\n    'planes',/" consultorio/settings.py && ./.venv/bin/python manage.py makemigrations planes 2>&1 | tail -6 && ./.venv/bin/python manage.py migrate 2>&1 | tail -3 && echo "=== líneas escritas por mí (sin lo generado) ===" && for f in planes/models.py planes/admin.py; do echo -n "$f: "; grep -vc '^\s*$' $f; done && echo "=== archivos que toqué ===" && echo "planes/models.py, planes/admin.py, consultorio/settings.py (1 línea)"

# --- 2026-09-13T02:56:11 · Verify Django row permissions and audit work
cd /tmp/claude-501/f12 && ./.venv/bin/python - <<'EOF'
import os, django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "consultorio.settings")
django.setup()
from django.contrib.auth.models import User
from django.test import Client
from planes.models import Branch, Profile, TreatmentPlan, AccessLog
from datetime import date
from decimal import Decimal

for n in ["Centro","Suba","Chapinero"]: Branch.objects.get_or_create(name=n)
suba = Branch.objects.get(name="Suba"); centro = Branch.objects.get(name="Centro")
for i in range(20):
    TreatmentPlan.objects.get_or_create(patient_document=str(10000000+i), defaults=dict(
        patient_name=f"Paciente {i}", branch=suba if i%2 else centro,
        opened_on=date(2026,3,1), total_amount=Decimal("12000000"),
        clinical_note="Apiñamiento severo, clase II"))
julian, _ = User.objects.get_or_create(username="julian", defaults={"is_staff":True,"is_superuser":True})
julian.set_password("x"); julian.save()
edgar, _ = User.objects.get_or_create(username="edgar", defaults={"is_staff":True})
edgar.set_password("x"); edgar.save()
Profile.objects.get_or_create(user=edgar, defaults={"branch": suba})
from django.contrib.auth.models import Permission
edgar.user_permissions.set(Permission.objects.filter(content_type__app_label="planes"))

c = Client()
c.login(username="julian", password="x")
r = c.get("/admin/planes/treatmentplan/")
print("Julián (superusuario) ve:", r.content.decode().count("Paciente"), "menciones · status", r.status_code)
c2 = Client(); c2.login(username="edgar", password="x")
r2 = c2.get("/admin/planes/treatmentplan/")
body = r2.content.decode()
print("Édgar ve:", body.count("Paciente"), "menciones · status", r2.status_code)
plan_centro = TreatmentPlan.objects.filter(branch=centro).first()
r3 = c2.get(f"/admin/planes/treatmentplan/{plan_centro.id}/change/?motivo=revision")
print("Édgar abriendo un plan de Centro:", r3.status_code, "(302/404 = no puede)")
print("accesos auditados:", AccessLog.objects.count())
plan_suba = TreatmentPlan.objects.filter(branch=suba).first()
r4 = c2.get(f"/admin/planes/treatmentplan/{plan_suba.id}/change/?motivo=revision+de+regalias")
print("Édgar abriendo uno de Suba:", r4.status_code, "· ¿ve la nota clínica?", "clinical_note" in r4.content.decode() or "nota clínica" in r4.content.decode())
print("accesos auditados ahora:", AccessLog.objects.count(), "·", AccessLog.objects.last().reason if AccessLog.objects.exists() else "")
EOF

# --- 2026-09-13T02:56:19 · Fix ALLOWED_HOSTS
cd /tmp/claude-501/f12 && grep -n "ALLOWED_HOSTS\|^DEBUG" consultorio/settings.py && sed -i '' 's/^ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = ["testserver", "localhost", "127.0.0.1"]/' consultorio/settings.py && grep -n "ALLOWED_HOSTS" consultorio/settings.py

# --- 2026-09-13T02:56:34 · Verify Django permissions and audit
cd /tmp/claude-501/f12 && ./.venv/bin/python - <<'EOF' 2>&1 | grep -v "^Invalid\|^Traceback\|^  File\|^    \|^django.core"
import os, django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "consultorio.settings")
django.setup()
from django.contrib.auth.models import User, Permission
from django.test import Client
from planes.models import Branch, Profile, TreatmentPlan, AccessLog
from datetime import date
from decimal import Decimal

for n in ["Centro","Suba","Chapinero"]: Branch.objects.get_or_create(name=n)
suba = Branch.objects.get(name="Suba"); centro = Branch.objects.get(name="Centro")
for i in range(20):
    TreatmentPlan.objects.get_or_create(patient_document=str(10000000+i), defaults=dict(
        patient_name=f"Paciente {i}", branch=suba if i%2 else centro,
        opened_on=date(2026,3,1), total_amount=Decimal("12000000"),
        clinical_note="Apiñamiento severo, clase II"))
julian, _ = User.objects.get_or_create(username="julian", defaults={"is_staff":True,"is_superuser":True})
julian.set_password("x"); julian.save()
edgar, _ = User.objects.get_or_create(username="edgar", defaults={"is_staff":True})
edgar.set_password("x"); edgar.save()
Profile.objects.get_or_create(user=edgar, defaults={"branch": suba})
edgar.user_permissions.set(Permission.objects.filter(content_type__app_label="planes"))

c = Client(); c.login(username="julian", password="x")
r = c.get("/admin/planes/treatmentplan/")
print("Julián (superusuario) ve:", r.content.decode().count("Paciente "), "planes · status", r.status_code)
c2 = Client(); c2.login(username="edgar", password="x")
r2 = c2.get("/admin/planes/treatmentplan/")
print("Édgar (Suba) ve:", r2.content.decode().count("Paciente "), "planes · status", r2.status_code)
plan_centro = TreatmentPlan.objects.filter(branch=centro).first()
r3 = c2.get(f"/admin/planes/treatmentplan/{plan_centro.id}/change/?motivo=revision")
print("Édgar abre un plan de Centro ->", r3.status_code)
plan_suba = TreatmentPlan.objects.filter(branch=suba).first()
r4 = c2.get(f"/admin/planes/treatmentplan/{plan_suba.id}/change/?motivo=revision+de+regalias")
b = r4.content.decode()
print("Édgar abre uno de Suba ->", r4.status_code, "· ¿aparece la nota clínica?", "Apiñamiento" in b)
r5 = c.get(f"/admin/planes/treatmentplan/{plan_suba.id}/change/?motivo=auditoria")
print("Julián abre el mismo -> ¿ve la nota?", "Apiñamiento" in r5.content.decode())
print("accesos auditados:", AccessLog.objects.count())
for a in AccessLog.objects.all()[:3]: print("   ", a.actor.username, a.action, a.plan_id, a.reason)
EOF

# --- 2026-09-13T02:56:46 · Set up FastAPI back-office environment
mkdir -p /tmp/claude-501/f12b/templates && cd /tmp/claude-501/f12b && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python 'fastapi==0.141.1' 'sqlalchemy==2.0.52' 'jinja2' 'python-multipart' 'itsdangerous' 'httpx==0.28.1' 'uvicorn==0.52.4' && echo instalado

# --- 2026-09-13T02:57:29 · Build the FastAPI back-office equivalent
cd /tmp/claude-501/f12b && cat > models.py <<'PYEOF'
"""Modelos del back-office."""

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import ForeignKey, Numeric, create_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, sessionmaker


class Base(DeclarativeBase):
    pass


class Branch(Base):
    __tablename__ = "branches"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(unique=True)


class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(unique=True)
    password_hash: Mapped[str]
    is_superuser: Mapped[bool] = mapped_column(default=False)
    branch_id: Mapped[int | None] = mapped_column(ForeignKey("branches.id"))


class TreatmentPlan(Base):
    __tablename__ = "treatment_plans"
    id: Mapped[int] = mapped_column(primary_key=True)
    patient_document: Mapped[str] = mapped_column(index=True)
    patient_name: Mapped[str]
    branch_id: Mapped[int] = mapped_column(ForeignKey("branches.id"))
    opened_on: Mapped[date]
    total_amount: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    status: Mapped[str] = mapped_column(default="open")
    clinical_note: Mapped[str] = mapped_column(default="")


class AccessLog(Base):
    __tablename__ = "access_log"
    id: Mapped[int] = mapped_column(primary_key=True)
    actor_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    at: Mapped[datetime] = mapped_column(default=datetime.now)
    action: Mapped[str]
    plan_id: Mapped[int] = mapped_column(ForeignKey("treatment_plans.id"))
    reason: Mapped[str]


engine = create_engine("sqlite:///backoffice.sqlite3")
SessionFactory = sessionmaker(engine)
PYEOF
cat > app.py <<'PYEOF'
"""El back-office en FastAPI: el mismo CRUD con permisos por fila y auditoría."""

import hashlib
from collections.abc import Iterator
from datetime import date
from decimal import Decimal
from typing import Annotated

from fastapi import Depends, FastAPI, Form, HTTPException, Request, status
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.orm import Session
from starlette.middleware.sessions import SessionMiddleware

from models import AccessLog, Branch, SessionFactory, TreatmentPlan, User

app = FastAPI()
app.add_middleware(SessionMiddleware, secret_key="cambiar-en-produccion")
templates = Jinja2Templates(directory="templates")


def get_session() -> Iterator[Session]:
    with SessionFactory() as session:
        yield session


def hash_password(raw: str) -> str:
    return hashlib.sha256(raw.encode()).hexdigest()


def current_user(request: Request,
                 session: Annotated[Session, Depends(get_session)]) -> User:
    user_id = request.session.get("user_id")
    if user_id is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "hay que iniciar sesión")
    user = session.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "sesión inválida")
    return user


CurrentUser = Annotated[User, Depends(current_user)]
DbSession = Annotated[Session, Depends(get_session)]


@app.get("/login", response_class=HTMLResponse)
def login_form(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(request, "login.html", {})


@app.post("/login")
def login(request: Request, session: DbSession,
          username: Annotated[str, Form()], password: Annotated[str, Form()]) -> RedirectResponse:
    user = session.scalar(select(User).where(User.username == username))
    if user is None or user.password_hash != hash_password(password):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "usuario o contraseña incorrectos")
    request.session["user_id"] = user.id
    return RedirectResponse("/plans", status_code=303)


@app.get("/logout")
def logout(request: Request) -> RedirectResponse:
    request.session.clear()
    return RedirectResponse("/login", status_code=303)


def visible_plans(user: User):
    """El permiso por fila. Tiene que aplicarse en TODAS las consultas."""
    stmt = select(TreatmentPlan)
    if not user.is_superuser:
        if user.branch_id is None:
            return stmt.where(False)
        stmt = stmt.where(TreatmentPlan.branch_id == user.branch_id)
    return stmt


@app.get("/plans", response_class=HTMLResponse)
def list_plans(request: Request, user: CurrentUser, session: DbSession,
               q: str = "", branch_id: int | None = None) -> HTMLResponse:
    stmt = visible_plans(user)
    if q:
        stmt = stmt.where(TreatmentPlan.patient_name.contains(q))
    if branch_id:
        stmt = stmt.where(TreatmentPlan.branch_id == branch_id)
    plans = session.scalars(stmt.order_by(TreatmentPlan.opened_on.desc())).all()
    branches = session.scalars(select(Branch)).all()
    return templates.TemplateResponse(
        request, "list.html",
        {"plans": plans, "branches": branches, "user": user, "q": q})


@app.get("/plans/{plan_id}", response_class=HTMLResponse)
def edit_form(request: Request, plan_id: int, user: CurrentUser, session: DbSession,
              motivo: str = "consulta administrativa") -> HTMLResponse:
    plan = session.scalar(visible_plans(user).where(TreatmentPlan.id == plan_id))
    if plan is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "no existe o no tiene acceso")
    session.add(AccessLog(actor_id=user.id, action="view", plan_id=plan_id, reason=motivo))
    session.commit()
    branches = session.scalars(select(Branch)).all()
    return templates.TemplateResponse(
        request, "edit.html",
        {"plan": plan, "branches": branches, "user": user,
         "show_note": user.is_superuser})


@app.post("/plans/{plan_id}")
def save_plan(request: Request, plan_id: int, user: CurrentUser, session: DbSession,
              patient_name: Annotated[str, Form()],
              patient_document: Annotated[str, Form()],
              branch_id: Annotated[int, Form()],
              opened_on: Annotated[date, Form()],
              total_amount: Annotated[Decimal, Form()],
              status_value: Annotated[str, Form(alias="status")]) -> RedirectResponse:
    plan = session.scalar(visible_plans(user).where(TreatmentPlan.id == plan_id))
    if plan is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "no existe o no tiene acceso")
    if not user.is_superuser and branch_id != user.branch_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "no puede mover un plan a otra sede")
    plan.patient_name = patient_name
    plan.patient_document = patient_document
    plan.branch_id = branch_id
    plan.opened_on = opened_on
    plan.total_amount = total_amount
    plan.status = status_value
    session.add(AccessLog(actor_id=user.id, action="edit", plan_id=plan_id,
                          reason="edición desde el back-office"))
    session.commit()
    return RedirectResponse("/plans", status_code=303)


@app.post("/plans/{plan_id}/delete")
def delete_plan(plan_id: int, user: CurrentUser, session: DbSession) -> RedirectResponse:
    plan = session.scalar(visible_plans(user).where(TreatmentPlan.id == plan_id))
    if plan is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "no existe o no tiene acceso")
    session.delete(plan)
    session.commit()
    return RedirectResponse("/plans", status_code=303)
PYEOF
cat > templates/base.html <<'EOF'
<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Consultorio · Áurea</title></head>
<body>
<nav><a href="/plans">Planes</a> · {{ user.username if user else "" }} · <a href="/logout">salir</a></nav>
<hr>
{% block content %}{% endblock %}
</body></html>
EOF
cat > templates/login.html <<'EOF'
{% extends "base.html" %}
{% block content %}
<h1>Ingresar</h1>
<form method="post" action="/login">
  <label>Usuario <input name="username" required></label>
  <label>Contraseña <input name="password" type="password" required></label>
  <button type="submit">Entrar</button>
</form>
{% endblock %}
EOF
cat > templates/list.html <<'EOF'
{% extends "base.html" %}
{% block content %}
<h1>Planes de tratamiento</h1>
<form method="get"><input name="q" value="{{ q }}" placeholder="paciente">
<select name="branch_id"><option value="">Todas las sedes</option>
{% for b in branches %}<option value="{{ b.id }}">{{ b.name }}</option>{% endfor %}</select>
<button>Buscar</button></form>
<table border="1">
<tr><th>Paciente</th><th>Documento</th><th>Sede</th><th>Apertura</th><th>Valor</th><th>Estado</th><th></th></tr>
{% for plan in plans %}
<tr><td>{{ plan.patient_name }}</td><td>{{ plan.patient_document }}</td>
<td>{{ plan.branch_id }}</td><td>{{ plan.opened_on }}</td>
<td>{{ "{:,.0f}".format(plan.total_amount) }}</td><td>{{ plan.status }}</td>
<td><a href="/plans/{{ plan.id }}?motivo=consulta">editar</a></td></tr>
{% endfor %}
</table>
{% endblock %}
EOF
cat > templates/edit.html <<'EOF'
{% extends "base.html" %}
{% block content %}
<h1>{{ plan.patient_name }}</h1>
<form method="post" action="/plans/{{ plan.id }}">
  <label>Paciente <input name="patient_name" value="{{ plan.patient_name }}" required></label>
  <label>Documento <input name="patient_document" value="{{ plan.patient_document }}" required></label>
  <label>Sede <select name="branch_id">
    {% for b in branches %}<option value="{{ b.id }}" {% if b.id == plan.branch_id %}selected{% endif %}>{{ b.name }}</option>{% endfor %}
  </select></label>
  <label>Apertura <input name="opened_on" type="date" value="{{ plan.opened_on }}"></label>
  <label>Valor <input name="total_amount" value="{{ plan.total_amount }}"></label>
  <label>Estado <select name="status">
    <option value="open" {% if plan.status=='open' %}selected{% endif %}>Abierto</option>
    <option value="done" {% if plan.status=='done' %}selected{% endif %}>Terminado</option>
    <option value="cancelled" {% if plan.status=='cancelled' %}selected{% endif %}>Cancelado</option>
  </select></label>
  {% if show_note %}<label>Nota clínica <textarea name="clinical_note">{{ plan.clinical_note }}</textarea></label>{% endif %}
  <button type="submit">Guardar</button>
</form>
<form method="post" action="/plans/{{ plan.id }}/delete"><button>Eliminar</button></form>
{% endblock %}
EOF
echo "=== líneas escritas (sin blancos) ===" && for f in models.py app.py templates/*.html; do echo -n "$f: "; grep -vc '^\s*$' $f; done && echo -n "TOTAL: " && cat models.py app.py templates/*.html | grep -vc '^\s*$'

# --- 2026-09-13T02:57:44 · Verify the FastAPI back-office
cd /tmp/claude-501/f12b && ./.venv/bin/python - <<'EOF'
from datetime import date
from decimal import Decimal
import hashlib, pathlib
pathlib.Path("backoffice.sqlite3").unlink(missing_ok=True)
from models import Base, engine, SessionFactory, Branch, User, TreatmentPlan, AccessLog
Base.metadata.create_all(engine)
h = lambda s: hashlib.sha256(s.encode()).hexdigest()
with SessionFactory() as s:
    centro, suba = Branch(name="Centro"), Branch(name="Suba")
    s.add_all([centro, suba]); s.flush()
    s.add(User(username="julian", password_hash=h("x"), is_superuser=True))
    s.add(User(username="edgar", password_hash=h("x"), branch_id=suba.id))
    for i in range(20):
        s.add(TreatmentPlan(patient_document=str(10000000+i), patient_name=f"Paciente {i}",
              branch_id=suba.id if i%2 else centro.id, opened_on=date(2026,3,1),
              total_amount=Decimal("12000000"), clinical_note="Apiñamiento severo, clase II"))
    s.commit()

from fastapi.testclient import TestClient
import app as A
c = TestClient(A.app)
c.post("/login", data={"username":"julian","password":"x"}, follow_redirects=False)
r = c.get("/plans"); print("Julián ve:", r.text.count("Paciente "), "planes ·", r.status_code)
c2 = TestClient(A.app)
c2.post("/login", data={"username":"edgar","password":"x"}, follow_redirects=False)
r2 = c2.get("/plans"); print("Édgar ve:", r2.text.count("Paciente "), "planes ·", r2.status_code)
with SessionFactory() as s:
    from sqlalchemy import select
    centro_id = s.scalar(select(Branch.id).where(Branch.name=="Centro"))
    pc = s.scalar(select(TreatmentPlan).where(TreatmentPlan.branch_id==centro_id))
    ps = s.scalar(select(TreatmentPlan).where(TreatmentPlan.branch_id!=centro_id))
    pc_id, ps_id = pc.id, ps.id
print("Édgar abre uno de Centro ->", c2.get(f"/plans/{pc_id}").status_code)
r4 = c2.get(f"/plans/{ps_id}?motivo=revision+de+regalias")
print("Édgar abre uno de Suba ->", r4.status_code, "· ¿nota clínica?", "Apiñamiento" in r4.text)
r5 = c.get(f"/plans/{ps_id}?motivo=auditoria")
print("Julián abre el mismo -> ¿nota?", "Apiñamiento" in r5.text)
with SessionFactory() as s:
    from sqlalchemy import func, select as sel
    print("accesos auditados:", s.scalar(sel(func.count()).select_from(AccessLog)))
EOF

# --- 2026-09-13T02:58:05 · Add a second entity in Django
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

# --- 2026-09-13T02:58:23 · Cost of the second entity in FastAPI
cd /tmp/claude-501/f12b && cat > _pantalla41.py <<'PYEOF'
# Lo que cuesta la segunda entidad en FastAPI: modelo + 3 rutas + 2 plantillas.

class Consent(Base):
    __tablename__ = "consents"
    id: Mapped[int] = mapped_column(primary_key=True)
    plan_id: Mapped[int] = mapped_column(ForeignKey("treatment_plans.id"))
    phase_kind: Mapped[str]
    signed_on: Mapped[date | None]
    document_ref: Mapped[str] = mapped_column(default="")


def visible_consents(user: User):
    stmt = select(Consent).join(TreatmentPlan, TreatmentPlan.id == Consent.plan_id)
    if not user.is_superuser:
        if user.branch_id is None:
            return stmt.where(False)
        stmt = stmt.where(TreatmentPlan.branch_id == user.branch_id)
    return stmt


@app.get("/consents", response_class=HTMLResponse)
def list_consents(request: Request, user: CurrentUser, session: DbSession,
                  q: str = "", phase_kind: str = "") -> HTMLResponse:
    stmt = visible_consents(user)
    if q:
        stmt = stmt.where(Consent.document_ref.contains(q))
    if phase_kind:
        stmt = stmt.where(Consent.phase_kind == phase_kind)
    consents = session.scalars(stmt.order_by(Consent.signed_on.desc())).all()
    return templates.TemplateResponse(
        request, "consents_list.html", {"consents": consents, "user": user, "q": q})


@app.get("/consents/{consent_id}", response_class=HTMLResponse)
def edit_consent_form(request: Request, consent_id: int, user: CurrentUser,
                      session: DbSession) -> HTMLResponse:
    consent = session.scalar(visible_consents(user).where(Consent.id == consent_id))
    if consent is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "no existe o no tiene acceso")
    return templates.TemplateResponse(
        request, "consents_edit.html", {"consent": consent, "user": user})


@app.post("/consents/{consent_id}")
def save_consent(consent_id: int, user: CurrentUser, session: DbSession,
                 phase_kind: Annotated[str, Form()],
                 signed_on: Annotated[date | None, Form()] = None,
                 document_ref: Annotated[str, Form()] = "") -> RedirectResponse:
    consent = session.scalar(visible_consents(user).where(Consent.id == consent_id))
    if consent is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "no existe o no tiene acceso")
    consent.phase_kind = phase_kind
    consent.signed_on = signed_on
    consent.document_ref = document_ref
    session.commit()
    return RedirectResponse("/consents", status_code=303)
PYEOF
cat > templates/consents_list.html <<'EOF'
{% extends "base.html" %}
{% block content %}
<h1>Consentimientos</h1>
<form method="get"><input name="q" value="{{ q }}" placeholder="soporte">
<input name="phase_kind" placeholder="fase"><button>Buscar</button></form>
<table border="1">
<tr><th>Plan</th><th>Fase</th><th>Firma</th><th>Soporte</th><th></th></tr>
{% for c in consents %}
<tr><td>{{ c.plan_id }}</td><td>{{ c.phase_kind }}</td><td>{{ c.signed_on }}</td>
<td>{{ c.document_ref }}</td><td><a href="/consents/{{ c.id }}">editar</a></td></tr>
{% endfor %}
</table>
{% endblock %}
EOF
cat > templates/consents_edit.html <<'EOF'
{% extends "base.html" %}
{% block content %}
<h1>Consentimiento del plan {{ consent.plan_id }}</h1>
<form method="post" action="/consents/{{ consent.id }}">
  <label>Fase <input name="phase_kind" value="{{ consent.phase_kind }}" required></label>
  <label>Firma <input name="signed_on" type="date" value="{{ consent.signed_on or '' }}"></label>
  <label>Soporte <input name="document_ref" value="{{ consent.document_ref }}"></label>
  <button type="submit">Guardar</button>
</form>
{% endblock %}
EOF
echo "=== la pantalla 41 en FastAPI cuesta ===" && for f in _pantalla41.py templates/consents_list.html templates/consents_edit.html; do echo -n "$f: "; grep -vc '^\s*$' $f; done && echo -n "TOTAL: " && cat _pantalla41.py templates/consents_list.html templates/consents_edit.html | grep -vc '^\s*$'

# --- 2026-09-13T03:03:04 · Stop Postgres and check structure
export PATH=/opt/homebrew/opt/postgresql@18/bin:$PATH; pg_ctl -D /tmp/claude-501/pgdata stop >/dev/null 2>&1; echo "postgres detenido"; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && for f in 0*.md 1*.md; do case "$f" in 0-*|00-conv*|README*) continue;; esac; n=$(grep -c '^## ' "$f"); t=$(grep -c 'git tag -a fase-' "$f"); e=$(grep -oE '^## 🧪 8\. Ejercicios \([0-9]+\)' "$f" | grep -oE '[0-9]+'); echo "$f · secciones=$n · tag=$t · ejercicios=${e:-n/a} · $(wc -c < "$f") bytes"; done

# --- 2026-09-13T03:08:23 · Check for free-threaded Python
export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv; /tmp/claude-501/mgr/.tool-uv/bin/uv python list 2>/dev/null | grep -i "3.14" | head -10; echo "--- instalando free-threaded ---"; UV_PYTHON_INSTALL_DIR=/tmp/claude-501/uvpy /tmp/claude-501/mgr/.tool-uv/bin/uv python install 3.14t 2>&1 | tail -3

# --- 2026-09-13T03:08:33 · Verify the free-threaded interpreter
FT=$(find /tmp/claude-501/uvpy -name "python3.14t" -type f 2>/dev/null | head -1); echo "binario: $FT"; $FT -VV; $FT -c "import sys; print('GIL activo:', sys._is_gil_enabled())"; echo "--- y el normal 3.14.7 ---"; /tmp/claude-501/mgr/uvpy/cpython-3.14.7-macos-aarch64-none/bin/python3.14 -VV

# --- 2026-09-13T03:09:03 · Build the failing partner server
mkdir -p /tmp/claude-501/f13 && cd /tmp/claude-501/f13 && cat > socio_falible.py <<'PYEOF'
"""Servidor de pruebas que falla a propósito, para la Fase 13.

Imita a los tres socios de Áurea que reciben los webhooks de disponibilidad.
No es código a imitar: es un sistema ajeno, con los fallos que tienen los
sistemas ajenos de verdad.

Uso:
    python socio_falible.py [--puerto 8099] [--semilla 2026]

Comportamiento por ruta:
  /lento          responde bien, pero tarda entre 2 y 6 segundos
  /intermitente   uno de cada tres intentos devuelve 500
  /truncado       responde 200 con el cuerpo cortado a la mitad
  /mentiroso      responde 200 SIEMPRE y no procesa nada (el peor de todos)
  /firmado        exige la cabecera X-Firma correcta; si no, 401
  /idempotente    respeta la cabecera Idempotency-Key y no duplica

Todas las rutas registran lo que recibieron en memoria, y GET /_recibidos
devuelve el registro para poder auditar qué llegó de verdad.
"""

import argparse
import hashlib
import hmac
import json
import random
import threading
import time
from collections import defaultdict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SECRET = b"el-secreto-que-comparten-aurea-y-el-socio"
received: dict[str, list[dict]] = defaultdict(list)
processed_keys: dict[str, str] = {}
attempts: dict[str, int] = defaultdict(int)
lock = threading.Lock()


class SocioHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):
        """Silencio: el ruido del servidor estorba en la medición."""

    def _read_body(self) -> bytes:
        length = int(self.headers.get("Content-Length", 0))
        return self.rfile.read(length) if length else b""

    def _respond(self, code: int, payload: dict, truncate: bool = False) -> None:
        body = json.dumps(payload).encode()
        if truncate:
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body[: len(body) // 2])   # cuerpo cortado a la mitad
            return
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/_recibidos":
            with lock:
                payload = {k: len(v) for k, v in received.items()}
                payload["_claves_procesadas"] = len(processed_keys)
            self._respond(200, payload)
            return
        if self.path == "/_reiniciar":
            with lock:
                received.clear(); processed_keys.clear(); attempts.clear()
            self._respond(200, {"ok": True})
            return
        self._respond(404, {"error": "no existe"})

    def do_POST(self):
        body = self._read_body()
        route = self.path.split("?")[0]

        with lock:
            attempts[route] += 1
            attempt = attempts[route]

        if route == "/lento":
            time.sleep(random.uniform(2.0, 6.0))
            with lock:
                received[route].append(json.loads(body or b"{}"))
            self._respond(200, {"ok": True})

        elif route == "/intermitente":
            if attempt % 3 == 0:
                self._respond(500, {"error": "error interno del socio"})
                return
            with lock:
                received[route].append(json.loads(body or b"{}"))
            self._respond(200, {"ok": True})

        elif route == "/truncado":
            with lock:
                received[route].append(json.loads(body or b"{}"))
            self._respond(200, {"ok": True, "detalle": "x" * 400}, truncate=True)

        elif route == "/mentiroso":
            # Responde 200 y NO guarda nada. Es el fallo más difícil de detectar.
            self._respond(200, {"ok": True})

        elif route == "/firmado":
            expected = hmac.new(SECRET, body, hashlib.sha256).hexdigest()
            if not hmac.compare_digest(self.headers.get("X-Firma", ""), expected):
                self._respond(401, {"error": "firma inválida"})
                return
            with lock:
                received[route].append(json.loads(body or b"{}"))
            self._respond(200, {"ok": True})

        elif route == "/idempotente":
            key = self.headers.get("Idempotency-Key", "")
            with lock:
                if key and key in processed_keys:
                    self._respond(200, {"ok": True, "repetido": True})
                    return
                received[route].append(json.loads(body or b"{}"))
                if key:
                    processed_keys[key] = "ok"
            # Falla una de cada tres DESPUÉS de haber procesado: el caso que
            # obliga a que el emisor reintente sobre algo ya hecho.
            if attempt % 3 == 0:
                self._respond(500, {"error": "falló al responder, pero ya procesé"})
                return
            self._respond(200, {"ok": True})

        else:
            self._respond(404, {"error": "no existe"})


def main() -> None:
    parser = argparse.ArgumentParser(description="Socio que falla a propósito.")
    parser.add_argument("--puerto", type=int, default=8099)
    parser.add_argument("--semilla", type=int, default=2026)
    args = parser.parse_args()

    random.seed(args.semilla)
    server = ThreadingHTTPServer(("127.0.0.1", args.puerto), SocioHandler)
    print(f"socio falible escuchando en http://127.0.0.1:{args.puerto}")
    server.serve_forever()


if __name__ == "__main__":
    main()
PYEOF
/opt/homebrew/bin/python3.14 -c "import ast; ast.parse(open('/tmp/claude-501/f13/socio_falible.py').read()); print('sintaxis OK')"

# --- 2026-09-13T03:09:22 · Measure loss and duplication with and without defenses
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

# --- 2026-09-13T03:09:45 · Measure the slow partner with and without timeout
cd /tmp/claude-501/f13 && ./.venv/bin/python - <<'EOF'
import time, httpx
BASE="http://127.0.0.1:8099"
httpx.get(f"{BASE}/_reiniciar")
N=10
print("=== el socio lento (tarda entre 2 y 6 s) ===")
# sin timeout: el emisor se bloquea con cada notificación
t0=time.perf_counter()
with httpx.Client(timeout=None) as c:
    for i in range(N):
        c.post(f"{BASE}/lento", json={"evento": i})
sin_to = time.perf_counter()-t0
llegaron_sin = httpx.get(f"{BASE}/_recibidos").json().get("/lento", 0)
httpx.get(f"{BASE}/_reiniciar")
# con timeout de 1 s: se abandona rápido, pero se pierde
t0=time.perf_counter(); perdidas=0
with httpx.Client(timeout=1.0) as c:
    for i in range(N):
        try: c.post(f"{BASE}/lento", json={"evento": i})
        except httpx.TimeoutException: perdidas+=1
con_to = time.perf_counter()-t0
time.sleep(7)  # el servidor sigue procesando en segundo plano
llegaron_con = httpx.get(f"{BASE}/_recibidos").json().get("/lento", 0)
print(f"sin timeout: {sin_to:6.1f} s para {N} notificaciones · llegaron {llegaron_sin}")
print(f"con timeout de 1 s: {con_to:6.1f} s · el emisor dio por perdidas {perdidas} · pero al socio LLEGARON {llegaron_con}")
EOF

# --- 2026-09-13T03:15:32 · Verify the documented server and save the asset
pkill -f socio_falible; cd /tmp/claude-501/f13 && python3 - <<'EOF'
import re, pathlib
doc = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/13-integraciones.md").read_text()
srv = [b for b in re.findall(r"```python\n(.*?)```", doc, re.S) if b.startswith('"""Servidor de pruebas')][0]
pathlib.Path("socio_doc.py").write_text(srv)
EOF
(/opt/homebrew/bin/python3.14 socio_doc.py --puerto 8098 &) ; sleep 2 && ./.venv/bin/python - <<'EOF'
import httpx, hmac, hashlib, json
B="http://127.0.0.1:8098"
SECRET=b"el-secreto-que-comparten-aurea-y-el-socio"
print("intermitente x3:", [httpx.post(f"{B}/intermitente", json={"a":i}).status_code for i in range(3)])
body=json.dumps({"evento":1}).encode()
firma=hmac.new(SECRET, body, hashlib.sha256).hexdigest()
print("firmado con firma buena:", httpx.post(f"{B}/firmado", content=body, headers={"X-Firma":firma,"Content-Type":"application/json"}).status_code)
print("firmado con firma mala :", httpx.post(f"{B}/firmado", content=body, headers={"X-Firma":"00"*32}).status_code)
r=httpx.post(f"{B}/truncado", json={"a":1})
try:
    r.json(); print("truncado: se parseó (mal)")
except Exception as e: print("truncado:", r.status_code, "y el cuerpo revienta ->", type(e).__name__)
print("mentiroso:", httpx.post(f"{B}/mentiroso", json={"a":1}).status_code)
print("recibidos:", httpx.get(f"{B}/_recibidos").json())
EOF
pkill -f socio_doc; mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/13-integraciones && cp socio_doc.py /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/13-integraciones/socio_falible.py && echo "asset guardado"

# --- 2026-09-13T03:16:14 · Fix and re-verify the truncated response
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p="13-integraciones.md"; s=io.open(p,encoding="utf-8").read()

old = """    def _respond(self, code: int, payload: dict, truncate: bool = False) -> None:
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        # El cuerpo cortado a la mitad: el cliente ve un JSON inválido.
        self.wfile.write(body[: len(body) // 2] if truncate else body)"""
new = """    def _respond(self, code: int, payload: dict, truncate: bool = False) -> None:
        body = json.dumps(payload).encode()
        if truncate:
            # Cuerpo cortado a la mitad, con su Content-Length correcto: el
            # cliente recibe un 200 con un JSON que no se puede parsear.
            # (Una truncadura de verdad, donde el Content-Length miente, se
            # manifiesta como un timeout de lectura en vez de como JSON
            # inválido. Las dos existen; esta es la que se puede provocar de
            # forma determinista.)
            body = body[: len(body) // 2]
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)"""
assert old in s; s = s.replace(old, new)

old2 = """  /truncado       responde 200 con el cuerpo cortado a la mitad"""
new2 = """  /truncado       responde 200 con el cuerpo cortado: JSON inválido"""
assert old2 in s; s = s.replace(old2, new2)

old3 = """La segunda trampa está en `/truncado`: `httpx` te devuelve un `200` perfectamente válido, y el
cuerpo revienta al parsearlo. Si tu código hace `response.json()` dentro de un `try` que atrapa
todo, vas a convertir una respuesta corrupta en un reintento — o, peor, en un éxito."""
new3 = """La segunda trampa está en `/truncado`: `httpx` te devuelve un `200` perfectamente válido, y el
cuerpo revienta al parsearlo. Si tu código hace `response.json()` dentro de un `try` que atrapa
todo, vas a convertir una respuesta corrupta en un reintento — o, peor, en un éxito.

Y hay una variante peor que conviene conocer porque en producción es la que más se da: cuando el
servidor **miente en el `Content-Length`** y corta la conexión, el cliente se queda esperando los
bytes que faltan y lo que recibes no es un JSON inválido sino un **timeout de lectura** — sobre
una petición que el otro lado ya procesó. Es el mismo caso de §4, con otra cara: comprobado al
escribir esta fase, y la razón por la que el servidor de pruebas provoca la versión determinista."""
assert old3 in s; s = s.replace(old3, new3)
io.open(p,"w",encoding="utf-8").write(s); print("ok")
PYEOF
cd /tmp/claude-501/f13 && python3 -c "
import re,pathlib
doc=pathlib.Path('/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/13-integraciones.md').read_text()
srv=[b for b in re.findall(r'\`\`\`python\n(.*?)\`\`\`',doc,re.S) if b.startswith('\"\"\"Servidor de pruebas')][0]
pathlib.Path('socio_doc.py').write_text(srv)" && (/opt/homebrew/bin/python3.14 socio_doc.py --puerto 8097 &) && sleep 2 && ./.venv/bin/python -c "
import httpx
r=httpx.post('http://127.0.0.1:8097/truncado', json={'a':1}, timeout=3)
print('truncado ->', r.status_code, '· cuerpo:', r.text[:40])
try: r.json(); print('   se parseó (mal)')
except Exception as e: print('   json() ->', type(e).__name__)
print('recibidos:', httpx.get('http://127.0.0.1:8097/_recibidos').json())
"; pkill -f socio_doc; cp socio_doc.py /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/13-integraciones/socio_falible.py && echo "asset actualizado"

# --- 2026-09-13T03:16:35 · Build the CPU and IO workloads
mkdir -p /tmp/claude-501/f14 && cd /tmp/claude-501/f14 && cat > carga.py <<'PYEOF'
"""Las dos cargas del dominio de Áurea: una de CPU y una de E/S."""
import hashlib
import time
from decimal import Decimal


def reconcile_chunk(rows: list[tuple[str, str, str]]) -> tuple[int, Decimal]:
    """CPU pura: conciliar ventas contra lo facturado.

    Por cada fila: normaliza el documento, calcula el hash de control que exige
    la aseguradora, y suma en Decimal. Es trabajo real de Áurea y es todo CPU.
    """
    total = Decimal("0")
    matched = 0
    for document, code, amount in rows:
        clean = document.replace(".", "").strip()
        digest = hashlib.sha256(f"{clean}|{code}|{amount}".encode()).hexdigest()
        value = Decimal(amount)
        total += value
        if digest[0] in "0123456789":     # el criterio de control, simulado
            matched += 1
    return matched, total


def io_chunk(n: int) -> int:
    """E/S simulada: esperar a que un sistema ajeno responda.

    time.sleep libera el GIL, igual que lo libera una lectura de red o de disco.
    Es la forma honesta de simular E/S sin depender de un servidor.
    """
    for _ in range(n):
        time.sleep(0.01)
    return n
PYEOF
cat > generar.py <<'PYEOF'
"""Genera el archivo de ventas del trimestre para conciliar."""
import random
from pathlib import Path

def main() -> None:
    rng = random.Random(2026)
    Path("data").mkdir(exist_ok=True)
    target = Path("data") / "ventas-2026-Q1.csv"
    with target.open("w", encoding="utf-8") as f:
        f.write("documento,codigo,valor\n")
        for _ in range(1_200_000):
            f.write(f"{rng.randint(10_000_000, 1_299_999_999)},"
                    f"{rng.choice(['D8010','D8020','D2740','D7140','D1110','D8670'])},"
                    f"{rng.choice([75000,95000,120000,180000,210000,890000])}\n")
    print(f"{target}: 1.200.000 filas · {target.stat().st_size/1e6:.1f} MB")

if __name__ == "__main__":
    main()
PYEOF
/opt/homebrew/bin/python3.14 generar.py

# --- 2026-09-13T03:16:55 · Measure with the normal interpreter
cd /tmp/claude-501/f14 && cat > medir.py <<'PYEOF'
"""Las cuatro formas, sobre las dos cargas. Corre con python3.14 y con python3.14t."""
import concurrent.futures as cf
import os
import statistics
import sys
import time
from pathlib import Path

from carga import io_chunk, reconcile_chunk

WORKERS = 4
ROWS = 300_000          # subconjunto para que cada corrida dure segundos, no minutos


def load_rows(n: int) -> list[tuple[str, str, str]]:
    rows = []
    with open("data/ventas-2026-Q1.csv", encoding="utf-8") as f:
        next(f)
        for i, line in enumerate(f):
            if i >= n:
                break
            document, code, amount = line.rstrip("\n").split(",")
            rows.append((document, code, amount))
    return rows


def chunks(rows, n):
    size = len(rows) // n
    return [rows[i * size:(i + 1) * size if i < n - 1 else None] for i in range(n)]


def bench(fn, reps=3):
    fn()
    xs = []
    for _ in range(reps):
        t0 = time.perf_counter()
        fn()
        xs.append(time.perf_counter() - t0)
    xs.sort()
    return statistics.median(xs)


def main() -> None:
    gil = sys._is_gil_enabled() if hasattr(sys, "_is_gil_enabled") else True
    print(f"=== {sys.version.split()[0]} · GIL {'activo' if gil else 'DESACTIVADO'} "
          f"· {os.cpu_count()} núcleos · {WORKERS} trabajadores ===")

    rows = load_rows(ROWS)
    parts = chunks(rows, WORKERS)

    def cpu_secuencial():
        return [reconcile_chunk(p) for p in parts]

    def cpu_hilos():
        with cf.ThreadPoolExecutor(WORKERS) as ex:
            return list(ex.map(reconcile_chunk, parts))

    def cpu_procesos():
        with cf.ProcessPoolExecutor(WORKERS) as ex:
            return list(ex.map(reconcile_chunk, parts))

    io_parts = [25] * WORKERS      # 25 esperas de 10 ms por trabajador

    def io_secuencial():
        return [io_chunk(p) for p in io_parts]

    def io_hilos():
        with cf.ThreadPoolExecutor(WORKERS) as ex:
            return list(ex.map(io_chunk, io_parts))

    def io_procesos():
        with cf.ProcessPoolExecutor(WORKERS) as ex:
            return list(ex.map(io_chunk, io_parts))

    print(f"\n{'CPU (conciliar 300.000 filas)':<34}{'mediana':>12}{'aceleración':>14}")
    base = bench(cpu_secuencial)
    print(f"{'secuencial':<34}{base:>10.2f} s{'1.00×':>14}")
    for name, fn in [("hilos", cpu_hilos), ("procesos", cpu_procesos)]:
        t = bench(fn)
        print(f"{name:<34}{t:>10.2f} s{base/t:>13.2f}×")

    print(f"\n{'E/S (100 esperas de 10 ms)':<34}{'mediana':>12}{'aceleración':>14}")
    base_io = bench(io_secuencial)
    print(f"{'secuencial':<34}{base_io:>10.2f} s{'1.00×':>14}")
    for name, fn in [("hilos", io_hilos), ("procesos", io_procesos)]:
        t = bench(fn)
        print(f"{name:<34}{t:>10.2f} s{base_io/t:>13.2f}×")


if __name__ == "__main__":
    main()
PYEOF
echo "### INTÉRPRETE NORMAL (con GIL) ###" && /tmp/claude-501/mgr/uvpy/cpython-3.14.7-macos-aarch64-none/bin/python3.14 medir.py

# --- 2026-09-13T03:17:18 · Re-measure with the full file
cd /tmp/claude-501/f14 && sed -i '' 's/^ROWS = 300_000.*/ROWS = 1_200_000        # el archivo completo del trimestre/' medir.py && sed -i '' 's/conciliar 300.000 filas/conciliar 1.200.000 filas/' medir.py && echo "### CON GIL ###" && /tmp/claude-501/mgr/uvpy/cpython-3.14.7-macos-aarch64-none/bin/python3.14 medir.py

# --- 2026-09-13T03:17:55 · Add the no-serialization process variant
cd /tmp/claude-501/f14 && cat >> carga.py <<'PYEOF'


def reconcile_slice(job: tuple[str, int, int]) -> tuple[int, Decimal]:
    """Lo mismo, pero el proceso lee su propio pedazo del archivo.

    La diferencia con reconcile_chunk no es el cálculo —es idéntico— sino que
    los datos NO cruzan la frontera entre procesos: solo cruzan tres números.
    """
    path, start, count = job
    rows = []
    with open(path, encoding="utf-8") as file:
        next(file)
        for index, line in enumerate(file):
            if index < start:
                continue
            if len(rows) >= count:
                break
            document, code, amount = line.rstrip("\n").split(",")
            rows.append((document, code, amount))
    return reconcile_chunk(rows)
PYEOF
python3 - <<'EOF'
import io
p="/tmp/claude-501/f14/medir.py"; s=io.open(p).read()
s = s.replace("from carga import io_chunk, reconcile_chunk",
              "from carga import io_chunk, reconcile_chunk, reconcile_slice")
s = s.replace("""    io_parts = [25] * WORKERS""",
"""    size = ROWS // WORKERS
    jobs = [("data/ventas-2026-Q1.csv", i * size, size) for i in range(WORKERS)]

    def cpu_procesos_sin_serializar():
        with cf.ProcessPoolExecutor(WORKERS) as ex:
            return list(ex.map(reconcile_slice, jobs))

    io_parts = [25] * WORKERS""")
s = s.replace("""    for name, fn in [("hilos", cpu_hilos), ("procesos", cpu_procesos)]:""",
"""    for name, fn in [("hilos", cpu_hilos),
                     ("procesos (datos serializados)", cpu_procesos),
                     ("procesos (cada uno lee lo suyo)", cpu_procesos_sin_serializar)]:""")
io.open(p,"w").write(s); print("ok")
EOF
echo "### CON GIL ###" && /tmp/claude-501/mgr/uvpy/cpython-3.14.7-macos-aarch64-none/bin/python3.14 medir.py

# --- 2026-09-13T03:18:24 · Measure with the free-threaded interpreter
cd /tmp/claude-501/f14 && echo "### SIN GIL (free-threading) ###" && /tmp/claude-501/uvpy/cpython-3.14.7+freethreaded-macos-aarch64-none/bin/python3.14t medir.py

# --- 2026-09-13T03:19:01 · Sanity check free-threading with pure Python
cd /tmp/claude-501/f14 && cat > sanity.py <<'PYEOF'
"""¿El intérprete paraleliza de verdad? Carga de Python puro, sin extensiones C."""
import concurrent.futures as cf, statistics, sys, time

def spin(n: int) -> int:
    """Aritmética pura de Python: sin hashlib, sin Decimal, sin objetos nuevos."""
    total = 0
    for i in range(n):
        total += i * i % 7
    return total

N = 4_000_000
W = 4

def bench(fn, reps=3):
    fn(); xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(); xs.append(time.perf_counter()-t0)
    xs.sort(); return statistics.median(xs)

gil = sys._is_gil_enabled() if hasattr(sys,"_is_gil_enabled") else True
seq = bench(lambda: [spin(N) for _ in range(W)])
def hilos():
    with cf.ThreadPoolExecutor(W) as ex: return list(ex.map(spin, [N]*W))
thr = bench(hilos)
print(f"GIL {'activo' if gil else 'DESACTIVADO'}: secuencial {seq:.2f}s · hilos {thr:.2f}s · {seq/thr:.2f}×")
PYEOF
echo -n "normal   -> "; /tmp/claude-501/mgr/uvpy/cpython-3.14.7-macos-aarch64-none/bin/python3.14 sanity.py
echo -n "sin GIL  -> "; /tmp/claude-501/uvpy/cpython-3.14.7+freethreaded-macos-aarch64-none/bin/python3.14t sanity.py

# --- 2026-09-13T03:19:27 · Measure the single-thread penalty of free-threading
cd /tmp/claude-501/f14 && cat > penalizacion.py <<'PYEOF'
"""¿Cuánto cuesta el free-threading cuando NO usas hilos?"""
import statistics, sys, time
from carga import reconcile_chunk

rows=[]
with open("data/ventas-2026-Q1.csv", encoding="utf-8") as f:
    next(f)
    for i, line in enumerate(f):
        if i >= 400_000: break
        rows.append(tuple(line.rstrip("\n").split(",")))

def bench(fn, reps=7):
    fn(); xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(); xs.append(time.perf_counter()-t0)
    xs.sort(); return statistics.median(xs)

gil = sys._is_gil_enabled() if hasattr(sys,"_is_gil_enabled") else True
t = bench(lambda: reconcile_chunk(rows))
print(f"{'GIL activo' if gil else 'sin GIL':>12}: un solo hilo, 400.000 filas -> {t:.3f} s")
PYEOF
/tmp/claude-501/mgr/uvpy/cpython-3.14.7-macos-aarch64-none/bin/python3.14 penalizacion.py
/tmp/claude-501/uvpy/cpython-3.14.7+freethreaded-macos-aarch64-none/bin/python3.14t penalizacion.py

# --- 2026-09-13T03:19:53 · Measure asyncio on the IO workload
cd /tmp/claude-501/f14 && cat > medir_async.py <<'PYEOF'
"""asyncio contra hilos contra secuencial, en la carga de E/S."""
import asyncio, concurrent.futures as cf, statistics, sys, time

W, PER = 4, 25          # 4 trabajadores, 25 esperas de 10 ms cada uno

def io_chunk(n):
    for _ in range(n): time.sleep(0.01)
    return n

async def io_chunk_async(n):
    for _ in range(n): await asyncio.sleep(0.01)
    return n

async def con_taskgroup():
    async with asyncio.TaskGroup() as tg:
        tareas = [tg.create_task(io_chunk_async(PER)) for _ in range(W)]
    return [t.result() for t in tareas]

async def mal_asyncio():
    """El error: bloquear el bucle con time.sleep dentro de una corrutina."""
    async def bloqueante(n):
        for _ in range(n): time.sleep(0.01)   # ← bloquea a TODOS
        return n
    async with asyncio.TaskGroup() as tg:
        [tg.create_task(bloqueante(PER)) for _ in range(W)]

def bench(fn, reps=3):
    fn(); xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(); xs.append(time.perf_counter()-t0)
    xs.sort(); return statistics.median(xs)

gil = sys._is_gil_enabled() if hasattr(sys,"_is_gil_enabled") else True
print(f"=== {sys.version.split()[0]} · GIL {'activo' if gil else 'DESACTIVADO'} ===")
base = bench(lambda: [io_chunk(PER) for _ in range(W)])
print(f"{'secuencial':<38}{base:>8.2f} s{'1.00×':>12}")
def hilos():
    with cf.ThreadPoolExecutor(W) as ex: return list(ex.map(io_chunk, [PER]*W))
t=bench(hilos); print(f"{'hilos':<38}{t:>8.2f} s{base/t:>11.2f}×")
t=bench(lambda: asyncio.run(con_taskgroup())); print(f"{'asyncio con TaskGroup':<38}{t:>8.2f} s{base/t:>11.2f}×")
t=bench(lambda: asyncio.run(mal_asyncio())); print(f"{'asyncio con time.sleep adentro (mal)':<38}{t:>8.2f} s{base/t:>11.2f}×")
PYEOF
/tmp/claude-501/mgr/uvpy/cpython-3.14.7-macos-aarch64-none/bin/python3.14 medir_async.py

# --- 2026-09-13T03:20:27 · Measure the double-booking race
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

# --- 2026-09-13T03:20:49 · Demonstrate the useless threading.Lock across processes
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

# --- 2026-09-13T03:25:16 · Fix the text slip and save F14 asset
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p="14-concurrencia-y-gil.md"; s=io.open(p,encoding="utf-8").read()
old = "y el free-threading sobre esta carga concreta apenas llega a 1.14% —perdón, **1.14×**— porque el\ntrabajo vive en `hashlib` y `Decimal`."
new = "y el free-threading sobre esta carga concreta apenas llega a **1.14×**, porque el trabajo vive\ndentro de `hashlib` y `Decimal`."
assert old in s, s[s.find("perdón")-200:s.find("perdón")+200]
io.open(p,"w",encoding="utf-8").write(s.replace(old,new)); print("ok")
PYEOF
mkdir -p src/14-concurrencia-y-gil && cd /tmp/claude-501/f14 && python3 -c "
import re,pathlib
doc=pathlib.Path('/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/14-concurrencia-y-gil.md').read_text()
gen=[b for b in re.findall(r'\`\`\`python\n(.*?)\`\`\`',doc,re.S) if b.startswith('\"\"\"Genera el archivo de ventas')][0]
pathlib.Path('generar_ventas_doc.py').write_text(gen)" && /opt/homebrew/bin/python3.14 generar_ventas_doc.py && cp generar_ventas_doc.py /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/14-concurrencia-y-gil/generar_ventas.py && echo "asset guardado"

# --- 2026-09-13T03:25:26 · Fix the text slip
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import io
p="14-concurrencia-y-gil.md"; s=io.open(p,encoding="utf-8").read()
old = "free-threading sobre esta carga concreta apenas llega a 1.14% —perdón, **1.14×**— porque el\ntrabajo vive en `hashlib` y `Decimal`."
new = "free-threading sobre esta carga concreta apenas llega a **1.14×**, porque el trabajo vive dentro\nde `hashlib` y `Decimal`."
assert old in s
io.open(p,"w",encoding="utf-8").write(s.replace(old,new))
print("ok ·", "perdón" in s.replace(old,new))
PYEOF

# --- 2026-09-13T03:25:36 · Read scope of phases 15-17
sed -n '700,800p' prompts/propuesta-fases-y-alcance.md

# --- 2026-09-13T03:26:04 · Measure checkpointed vs all-or-nothing batch
mkdir -p /tmp/claude-501/f15 && cd /tmp/claude-501/f15 && cp /tmp/claude-501/f14/data/ventas-2026-Q1.csv . 2>/dev/null; cat > medir_cierre.py <<'PYEOF'
"""El cierre nocturno con un fallo inyectado, con punto de control y sin él."""
import sqlite3, statistics, time
from decimal import Decimal
from pathlib import Path

FUENTE = Path("ventas-2026-Q1.csv")
LOTE = 20_000            # filas por punto de control
FALLO_EN = 0.80          # el fallo ocurre al 80% del trabajo (la "hora cinco")


class FalloInyectado(Exception):
    """El fallo de la hora cinco: la base se cae, la red se corta, lo que sea."""


def trabajo(fila: tuple[str, str, str]) -> Decimal:
    """Lo que cuesta procesar una fila del cierre."""
    documento, codigo, valor = fila
    return Decimal(valor) * Decimal("0.15")


def leer(desde: int, cuantas: int):
    with FUENTE.open(encoding="utf-8") as f:
        next(f)
        for i, linea in enumerate(f):
            if i < desde: continue
            if cuantas is not None and i >= desde + cuantas: break
            yield tuple(linea.rstrip("\n").split(","))


def total_filas() -> int:
    with FUENTE.open(encoding="utf-8") as f:
        return sum(1 for _ in f) - 1


N = total_filas()


def sin_checkpoint(fallar: bool):
    """Todo o nada: si falla, se pierde todo y hay que empezar de cero."""
    total = Decimal("0"); hechas = 0
    for fila in leer(0, None):
        if fallar and hechas >= int(N * FALLO_EN):
            raise FalloInyectado(f"cayó tras {hechas:,} filas")
        total += trabajo(fila); hechas += 1
    return hechas, total


def con_checkpoint(fallar: bool, db: Path):
    """Reanudable: cada lote confirma su avance en la misma transacción."""
    con = sqlite3.connect(db)
    con.execute("CREATE TABLE IF NOT EXISTS avance (id INTEGER PRIMARY KEY CHECK (id=1), hechas INT, total TEXT)")
    fila = con.execute("SELECT hechas, total FROM avance WHERE id=1").fetchone()
    hechas, total = (fila[0], Decimal(fila[1])) if fila else (0, Decimal("0"))

    while hechas < N:
        lote_total = Decimal("0"); lote_hechas = 0
        for f in leer(hechas, LOTE):
            if fallar and hechas + lote_hechas >= int(N * FALLO_EN):
                con.close()
                raise FalloInyectado(f"cayó tras {hechas + lote_hechas:,} filas")
            lote_total += trabajo(f); lote_hechas += 1
        if lote_hechas == 0: break
        # El avance y el resultado, en la MISMA transacción: o se confirman los dos o ninguno.
        with con:
            con.execute("INSERT INTO avance (id, hechas, total) VALUES (1, ?, ?) "
                        "ON CONFLICT(id) DO UPDATE SET hechas=excluded.hechas, total=excluded.total",
                        (hechas + lote_hechas, str(total + lote_total)))
        hechas += lote_hechas; total += lote_total
    con.close()
    return hechas, total


print(f"archivo: {N:,} filas · lote: {LOTE:,} · fallo inyectado al {FALLO_EN:.0%}\n")

t0=time.perf_counter(); sin_checkpoint(False); completo_sin = time.perf_counter()-t0
db = Path("avance.sqlite3"); db.unlink(missing_ok=True)
t0=time.perf_counter(); con_checkpoint(False, db); completo_con = time.perf_counter()-t0
print(f"{'cierre completo, sin punto de control':<46}{completo_sin:7.1f} s")
print(f"{'cierre completo, con punto de control':<46}{completo_con:7.1f} s"
      f"   (+{(completo_con/completo_sin-1)*100:.0f}% de sobrecosto)\n")

# Ahora el fallo
print("=== cae en la 'hora cinco' ===")
t0=time.perf_counter()
try: sin_checkpoint(True)
except FalloInyectado as e: print(f"sin punto de control: {e} · perdido TODO")
hasta_fallo = time.perf_counter()-t0
t0=time.perf_counter(); sin_checkpoint(False); recuperacion_sin = time.perf_counter()-t0
print(f"   tiempo hasta el fallo {hasta_fallo:.1f} s · recuperación (desde cero) {recuperacion_sin:.1f} s"
      f" · TOTAL {hasta_fallo+recuperacion_sin:.1f} s")

db.unlink(missing_ok=True)
t0=time.perf_counter()
try: con_checkpoint(True, db)
except FalloInyectado as e:
    con = sqlite3.connect(db); fila = con.execute("SELECT hechas FROM avance WHERE id=1").fetchone(); con.close()
    print(f"con punto de control: {e} · conservadas {fila[0]:,} filas")
hasta_fallo2 = time.perf_counter()-t0
t0=time.perf_counter(); hechas, _ = con_checkpoint(False, db); recuperacion_con = time.perf_counter()-t0
print(f"   tiempo hasta el fallo {hasta_fallo2:.1f} s · recuperación (reanudando) {recuperacion_con:.1f} s"
      f" · TOTAL {hasta_fallo2+recuperacion_con:.1f} s")
PYEOF
/opt/homebrew/bin/python3.14 medir_cierre.py

# --- 2026-09-13T03:26:49 · Re-measure with byte-offset checkpointing
cd /tmp/claude-501/f15 && cat > medir_cierre.py <<'PYEOF'
"""El cierre nocturno con un fallo inyectado, con punto de control y sin él."""
import hashlib, sqlite3, time
from decimal import Decimal
from pathlib import Path

FUENTE = Path("ventas-2026-Q1.csv")
LOTE = 20_000
FALLO_EN = 0.80


class FalloInyectado(Exception):
    """El fallo de la hora cinco: la base se cae, la red se corta, lo que sea."""


def trabajo(fila):
    """Lo que cuesta procesar una fila del cierre: liquidar su comisión."""
    documento, codigo, valor = fila
    hashlib.sha256(f"{documento}|{codigo}|{valor}".encode()).hexdigest()
    return Decimal(valor) * Decimal("0.15")


def total_filas():
    with FUENTE.open(encoding="utf-8") as f:
        return sum(1 for _ in f) - 1


N = total_filas()


def sin_checkpoint(fallar):
    """Todo o nada: si falla, se pierde todo y hay que empezar de cero."""
    total = Decimal("0"); hechas = 0
    with FUENTE.open(encoding="utf-8") as f:
        next(f)
        for linea in f:
            if fallar and hechas >= int(N * FALLO_EN):
                raise FalloInyectado(f"cayó tras {hechas:,} filas")
            total += trabajo(tuple(linea.rstrip("\n").split(","))); hechas += 1
    return hechas, total


def con_checkpoint(fallar, db):
    """Reanudable: el punto de control guarda el DESPLAZAMIENTO en bytes.

    Guardar el número de filas obligaría a releer y descartar lo ya hecho, que
    convierte la reanudación en cuadrática. El desplazamiento se busca con seek.
    """
    con = sqlite3.connect(db)
    con.execute("CREATE TABLE IF NOT EXISTS avance ("
                "id INTEGER PRIMARY KEY CHECK (id=1), offset INT, hechas INT, total TEXT)")
    fila = con.execute("SELECT offset, hechas, total FROM avance WHERE id=1").fetchone()
    offset, hechas, total = (fila[0], fila[1], Decimal(fila[2])) if fila else (0, 0, Decimal("0"))

    with FUENTE.open(encoding="utf-8") as f:
        if offset:
            f.seek(offset)
        else:
            next(f)
        while True:
            lote_total = Decimal("0"); lote_hechas = 0
            for linea in f:
                if fallar and hechas + lote_hechas >= int(N * FALLO_EN):
                    con.close()
                    raise FalloInyectado(f"cayó tras {hechas + lote_hechas:,} filas")
                lote_total += trabajo(tuple(linea.rstrip("\n").split(","))); lote_hechas += 1
                if lote_hechas >= LOTE:
                    break
            if lote_hechas == 0:
                break
            # El avance y el resultado, en la MISMA transacción.
            with con:
                con.execute(
                    "INSERT INTO avance (id, offset, hechas, total) VALUES (1,?,?,?) "
                    "ON CONFLICT(id) DO UPDATE SET offset=excluded.offset, "
                    "hechas=excluded.hechas, total=excluded.total",
                    (f.tell(), hechas + lote_hechas, str(total + lote_total)))
            hechas += lote_hechas; total += lote_total
    con.close()
    return hechas, total


print(f"archivo: {N:,} filas · lote: {LOTE:,} · fallo inyectado al {FALLO_EN:.0%}\n")
t0=time.perf_counter(); sin_checkpoint(False); a = time.perf_counter()-t0
db = Path("avance.sqlite3"); db.unlink(missing_ok=True)
t0=time.perf_counter(); con_checkpoint(False, db); b = time.perf_counter()-t0
print(f"{'cierre completo, sin punto de control':<46}{a:7.2f} s")
print(f"{'cierre completo, con punto de control':<46}{b:7.2f} s   (+{(b/a-1)*100:.0f}% de sobrecosto)\n")

print("=== cae en la 'hora cinco' (80% del trabajo hecho) ===")
t0=time.perf_counter()
try: sin_checkpoint(True)
except FalloInyectado as e: pass
h1 = time.perf_counter()-t0
t0=time.perf_counter(); sin_checkpoint(False); r1 = time.perf_counter()-t0
print(f"sin punto de control: se pierde TODO · hasta el fallo {h1:.2f} s + recuperación {r1:.2f} s = {h1+r1:.2f} s")

db.unlink(missing_ok=True)
t0=time.perf_counter()
try: con_checkpoint(True, db)
except FalloInyectado: pass
h2 = time.perf_counter()-t0
con = sqlite3.connect(db); guardadas = con.execute("SELECT hechas FROM avance WHERE id=1").fetchone()[0]; con.close()
t0=time.perf_counter(); hechas,_ = con_checkpoint(False, db); r2 = time.perf_counter()-t0
print(f"con punto de control: se conservan {guardadas:,} de {N:,} · hasta el fallo {h2:.2f} s"
      f" + recuperación {r2:.2f} s = {h2+r2:.2f} s")
print(f"\ntrabajo perdido: sin punto de control {int(N*FALLO_EN):,} filas · con punto de control "
      f"{int(N*FALLO_EN)-guardadas:,} filas")
PYEOF
/opt/homebrew/bin/python3.14 medir_cierre.py

# --- 2026-09-13T03:27:06 · Fix tell() and re-measure
cd /tmp/claude-501/f15 && python3 - <<'EOF'
import io
p="medir_cierre.py"; s=io.open(p).read()
s = s.replace("""        while True:
            lote_total = Decimal("0"); lote_hechas = 0
            for linea in f:
                if fallar and hechas + lote_hechas >= int(N * FALLO_EN):
                    con.close()
                    raise FalloInyectado(f"cayó tras {hechas + lote_hechas:,} filas")
                lote_total += trabajo(tuple(linea.rstrip("\\n").split(","))); lote_hechas += 1
                if lote_hechas >= LOTE:
                    break
            if lote_hechas == 0:
                break""",
"""        while True:
            lote_total = Decimal("0"); lote_hechas = 0
            while lote_hechas < LOTE:
                # readline() y no `for linea in f`: el iterador de archivo lee
                # por adelantado y deshabilita tell(), que es justo lo que el
                # punto de control necesita. Es un detalle del lenguaje y se
                # descubre con un OSError que no dice mucho.
                linea = f.readline()
                if not linea:
                    break
                if fallar and hechas + lote_hechas >= int(N * FALLO_EN):
                    con.close()
                    raise FalloInyectado(f"cayó tras {hechas + lote_hechas:,} filas")
                lote_total += trabajo(tuple(linea.rstrip("\\n").split(","))); lote_hechas += 1
            if lote_hechas == 0:
                break""")
s = s.replace("""        if offset:
            f.seek(offset)
        else:
            next(f)""",
"""        if offset:
            f.seek(offset)
        else:
            f.readline()      # el encabezado""")
io.open(p,"w").write(s)
EOF
/opt/homebrew/bin/python3.14 medir_cierre.py

# --- 2026-09-13T03:27:24 · Verify the batch can import the CLI as a library
cd /tmp/claude-501/f07 && ./.venv/bin/python -c "
from aur.summary import summarize
from aur.reading import read_rows
from pathlib import Path
s = summarize(read_rows(Path('data/centro-2026-03.csv')))
print('el batch importa el CLI como biblioteca:')
print(f\"  procedimientos {s['procedimientos']} · pacientes {s['pacientes']} · total \${s['total']:,.0f}\")
import aur; print('  aur', aur.__version__, 'desde', aur.__file__)
"

# --- 2026-09-13T03:32:04 · Install observability stack
mkdir -p /tmp/claude-501/f16 && cd /tmp/claude-501/f16 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python fastapi==0.141.1 uvicorn==0.52.4 httpx==0.28.1 structlog==26.1.0 'opentelemetry-sdk==1.44.0' 'opentelemetry-instrumentation-fastapi' 'prometheus-client==0.26.0' 2>&1 | tail -3; ./.venv/bin/python -c "import structlog, opentelemetry.sdk, prometheus_client; print('structlog', structlog.__version__)"

# --- 2026-09-13T03:32:24 · Measure logging cost per event
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

# --- 2026-09-13T03:32:39 · Measure logging cost and volume correctly
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

# --- 2026-09-13T03:32:56 · Measure logging volume correctly
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

# --- 2026-09-13T03:33:15 · Measure API latency with and without instrumentation
cd /tmp/claude-501/f16 && cat > app_instr.py <<'PYEOF'
"""La misma API, con instrumentación completa."""
import logging, sys
import structlog
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, SpanExporter, SpanExportResult
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

from app import app

class NullExporter(SpanExporter):
    """Exportador que descarta: mide el costo de INSTRUMENTAR, no el de la red."""
    def export(self, spans): return SpanExportResult.SUCCESS
    def shutdown(self): pass

provider = TracerProvider()
provider.add_span_processor(BatchSpanProcessor(NullExporter()))
trace.set_tracer_provider(provider)

f = open("api.log", "w")
structlog.configure(
    processors=[structlog.processors.add_log_level, structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.JSONRenderer()],
    logger_factory=structlog.WriteLoggerFactory(file=f))
log = structlog.get_logger()

@app.middleware("http")
async def registrar(request, call_next):
    response = await call_next(request)
    log.info("peticion", ruta=request.url.path, metodo=request.method,
             estado=response.status_code)
    return response

FastAPIInstrumentor.instrument_app(app)
PYEOF
for modo in "app:app|sin instrumentar" "app_instr:app|instrumentada"; do
  target="${modo%%|*}"; nombre="${modo##*|}"
  (./.venv/bin/uvicorn "$target" --port 8123 --log-level error &) ; sleep 3
  ./.venv/bin/python -c "
import httpx, statistics, time
with httpx.Client(base_url='http://127.0.0.1:8123') as c:
    for _ in range(40): c.get('/availability', params={'branch':'centro','day':'2026-10-15'})
    xs=[]
    for _ in range(300):
        t0=time.perf_counter(); c.get('/availability', params={'branch':'centro','day':'2026-10-15'}); xs.append((time.perf_counter()-t0)*1000)
xs.sort()
print(f'$nombre: mediana {statistics.median(xs):.2f} ms · p95 {xs[284]:.2f} ms')"
  pkill -f "uvicorn $target"; sleep 1
done

# --- 2026-09-13T03:33:47 · Profile the naive vs optimized close
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

# --- 2026-09-13T03:38:46 · Stop services and check markdown balance
export PATH=/opt/homebrew/opt/postgresql@18/bin:$PATH; pg_ctl -D /tmp/claude-501/pgdata stop >/dev/null 2>&1; pkill -f socio_falible; pkill -f uvicorn; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "Veredicto. El registro estructurado" 16-operacion-y-rendimiento.md && python3 -c "
import re,pathlib
for f in sorted(pathlib.Path('.').glob('1[3-6]-*.md')):
    s=f.read_text()
    # asteriscos dobles desbalanceados por línea
    malas=[i+1 for i,l in enumerate(s.splitlines()) if l.count('**')%2]
    print(f.name, '· líneas con ** impar:', malas[:6] if malas else 'ninguna')"

# --- 2026-09-13T03:38:54 · Inspect the nested bold
sed -n '474,478p' 16-operacion-y-rendimiento.md

# --- 2026-09-13T03:39:01 · Fix nested bold and check T5 structure
python3 - <<'PYEOF'
import io
p="16-operacion-y-rendimiento.md"; s=io.open(p,encoding="utf-8").read()
old = """> ⚖️ **Veredicto. El registro estructurado cuesta un 7% más de tiempo que el de texto y **2.8
> veces más volumen** —189 bytes contra 68—, y el volumen es lo único que hay que presupuestar de"""
new = """> ⚖️ **Veredicto.** El registro estructurado cuesta un 7% más de tiempo que el de texto y **2.8
> veces más volumen** —189 bytes contra 68—, y el volumen es lo único que hay que presupuestar de"""
assert old in s; io.open(p,"w",encoding="utf-8").write(s.replace(old,new)); print("ok")
PYEOF
for f in 1[3-6]-*.md; do n=$(grep -c '^## ' "$f"); t=$(grep -c 'git tag -a fase-' "$f"); e=$(grep -oE '^## 🧪 8\. Ejercicios \([0-9]+\)' "$f" | grep -oE '[0-9]+'); m=$(grep -c '^## 📏 6' "$f"); echo "$f · secciones=$n · tag=$t · ejercicios=$e · $(wc -c < "$f") bytes"; done; echo "--- assets ---"; ls src/*/

# --- 2026-09-13T03:49:28 · Check for Maven and Java versions
which mvn gradle 2>/dev/null; echo "--- java ---"; java -version 2>&1 | head -2; ls ~/.sdkman/candidates 2>/dev/null; echo "--- java disponibles ---"; ls ~/.sdkman/candidates/java 2>/dev/null

# --- 2026-09-13T03:49:41 · Test Maven can resolve Spring Boot
mkdir -p /tmp/claude-501/f17/agenda-java/src/main/java/co/aurea/agenda && cd /tmp/claude-501/f17/agenda-java && cat > pom.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.5.6</version>
    <relativePath/>
  </parent>
  <groupId>co.aurea</groupId>
  <artifactId>agenda</artifactId>
  <version>0.17.0</version>
  <properties>
    <java.version>21</java.version>
  </properties>
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
  </dependencies>
  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
EOF
export JAVA_HOME=~/.sdkman/candidates/java/21.0.8-zulu && export PATH=$JAVA_HOME/bin:$PATH && timeout 600 mvn -q -B help:evaluate -Dexpression=project.version -DforceStdout 2>&1 | tail -5

# --- 2026-09-13T03:50:06 · Check current Spring Boot version
curl -s "https://api.github.com/repos/spring-projects/spring-boot/releases?per_page=10" | python3 -c "
import sys,json
for r in json.load(sys.stdin):
    if not r['prerelease']: print(r['tag_name'], r['published_at'][:10])" 2>/dev/null | head -6

# --- 2026-09-13T03:50:26 · Build the Spring Boot competitor
cd /tmp/claude-501/f17/agenda-java && sed -i '' 's|<version>3.5.6</version>|<version>3.5.16</version>|' pom.xml && cat > src/main/java/co/aurea/agenda/AgendaApplication.java <<'EOF'
package co.aurea.agenda;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class AgendaApplication {
    public static void main(String[] args) {
        SpringApplication.run(AgendaApplication.class, args);
    }
}
EOF
cat > src/main/java/co/aurea/agenda/Availability.java <<'EOF'
package co.aurea.agenda;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;

public record Availability(String branch, LocalDate day, List<Slot> slots) {

    private static final ZoneOffset BOGOTA = ZoneOffset.ofHours(-5);

    public record Slot(OffsetDateTime startsAt, int minutes) {}

    public static Availability of(String branch, LocalDate day) {
        List<Slot> slots = new ArrayList<>(36);
        for (int hour = 7; hour < 19; hour++) {
            for (int minute : new int[] {0, 20, 40}) {
                slots.add(new Slot(OffsetDateTime.of(day, LocalTime.of(hour, minute), BOGOTA), 20));
            }
        }
        return new Availability(branch, day, slots);
    }
}
EOF
cat > src/main/java/co/aurea/agenda/AvailabilityController.java <<'EOF'
package co.aurea.agenda;

import java.time.LocalDate;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AvailabilityController {

    @GetMapping("/availability")
    public Availability availability(
            @RequestParam Branch branch,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate day) {
        return Availability.of(branch.name().toLowerCase(), day);
    }

    public enum Branch { CENTRO, CHAPINERO, SUBA, KENNEDY, USAQUEN }
}
EOF
cat > src/main/resources/application.properties <<'EOF'
spring.main.banner-mode=off
logging.level.root=WARN
server.port=8124
EOF
mkdir -p src/main/resources && export JAVA_HOME=~/.sdkman/candidates/java/21.0.8-zulu && export PATH=$JAVA_HOME/bin:$PATH && time mvn -q -B package -DskipTests 2>&1 | tail -15 && ls -lh target/*.jar

# --- 2026-09-13T03:51:02 · Rebuild and smoke-test Spring Boot
cd /tmp/claude-501/f17/agenda-java && mkdir -p src/main/resources && cat > src/main/resources/application.properties <<'EOF'
spring.main.banner-mode=off
logging.level.root=WARN
server.port=8124
EOF
export JAVA_HOME=~/.sdkman/candidates/java/21.0.8-zulu && export PATH=$JAVA_HOME/bin:$PATH && mvn -q -B package -DskipTests 2>&1 | tail -5 && ls -lh target/agenda-0.17.0.jar && (java -jar target/agenda-0.17.0.jar &) && sleep 8 && curl -s "http://127.0.0.1:8124/availability?branch=centro&day=2026-10-15" | head -c 200 && echo && echo "--- ok ---"

# --- 2026-09-13T03:51:25 · Add the converter and verify the endpoint
pkill -f agenda-0.17.0.jar; cd /tmp/claude-501/f17/agenda-java && cat > src/main/java/co/aurea/agenda/BranchConverter.java <<'EOF'
package co.aurea.agenda;

import co.aurea.agenda.AvailabilityController.Branch;
import java.util.Locale;
import org.springframework.core.convert.converter.Converter;
import org.springframework.stereotype.Component;

/** Acepta la sede en minúsculas, igual que la API de Python. */
@Component
public class BranchConverter implements Converter<String, Branch> {
    @Override
    public Branch convert(String source) {
        return Branch.valueOf(source.toUpperCase(Locale.ROOT));
    }
}
EOF
export JAVA_HOME=~/.sdkman/candidates/java/21.0.8-zulu && export PATH=$JAVA_HOME/bin:$PATH && mvn -q -B package -DskipTests 2>&1 | tail -3; (java -jar target/agenda-0.17.0.jar > /tmp/claude-501/f17/sb.log 2>&1 &) && sleep 8 && curl -s "http://127.0.0.1:8124/availability?branch=centro&day=2026-10-15" | python3 -c "import sys,json; d=json.load(sys.stdin); print('sede:', d['branch'], '· espacios:', len(d['slots']), '· primero:', d['slots'][0])"

# --- 2026-09-13T03:52:05 · Run the duel benchmark
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

# --- 2026-09-13T03:53:20 · Look for a load testing tool
which hey wrk oha ab bombardier k6 2>/dev/null; echo "---"; ls /opt/homebrew/bin | grep -iE "^(hey|wrk|oha|ab|bombardier|k6|siege|vegeta)$" 2>/dev/null; echo "--- ab del sistema ---"; ls /usr/sbin/ab 2>/dev/null || echo "no hay ab"

# --- 2026-09-13T03:53:31 · Benchmark with ApacheBench
cd /tmp/claude-501/f17 && export JAVA_HOME=~/.sdkman/candidates/java/21.0.8-zulu && (~/.sdkman/candidates/java/21.0.8-zulu/bin/java -jar agenda-java/target/agenda-0.17.0.jar > /dev/null 2>&1 &) && (./.venv/bin/python -m uvicorn app:app --port 8125 --log-level error > /dev/null 2>&1 &) && sleep 10 && for p in 8124 8125; do echo "=== puerto $p ==="; /usr/sbin/ab -n 200 -c 32 -q "http://127.0.0.1:$p/availability?branch=centro&day=2026-10-15" > /dev/null 2>&1; /usr/sbin/ab -n 20000 -c 32 -q "http://127.0.0.1:$p/availability?branch=centro&day=2026-10-15" 2>/dev/null | grep -E "Requests per second|Time per request|50%|95%|99%|Failed"; done

# --- 2026-09-13T03:54:05 · Benchmark uvicorn with multiple workers
pkill -f "uvicorn app:app"; cd /tmp/claude-501/f17 && for w in 2 4 8; do (./.venv/bin/python -m uvicorn app:app --port 8125 --workers $w --log-level error > /dev/null 2>&1 &); sleep 8; /usr/sbin/ab -n 200 -c 32 -q "http://127.0.0.1:8125/availability?branch=centro&day=2026-10-15" >/dev/null 2>&1; echo -n "uvicorn con $w trabajadores: "; /usr/sbin/ab -n 20000 -c 32 -q "http://127.0.0.1:8125/availability?branch=centro&day=2026-10-15" 2>/dev/null | grep -E "Requests per second" | awk '{printf "%s req/s  ", $4}'; /usr/sbin/ab -n 20000 -c 32 -q "http://127.0.0.1:8125/availability?branch=centro&day=2026-10-15" 2>/dev/null | grep -E "^  (50|95|99)%" | tr '\n' ' '; echo; pkill -f "uvicorn app:app"; sleep 2; done

# --- 2026-09-13T03:55:15 · Measure cold start and memory for both
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

# --- 2026-09-13T03:55:28 · Re-measure cold start and memory
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

# --- 2026-09-13T03:57:03 · Re-measure with a free-port assertion
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

# --- 2026-09-13T03:59:00 · Count lines and check Docker
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

# --- 2026-09-13T03:59:15 · Build the fair LOC comparison
cd /tmp/claude-501/f17 && cat > app_duelo.py <<'PYEOF'
"""El endpoint del duelo: solo disponibilidad, igual que el de Java."""

from datetime import date, datetime, time, timedelta, timezone
from enum import StrEnum

from fastapi import FastAPI
from pydantic import BaseModel

BOGOTA = timezone(timedelta(hours=-5))


class Branch(StrEnum):
    CENTRO = "centro"
    CHAPINERO = "chapinero"
    SUBA = "suba"
    KENNEDY = "kennedy"
    USAQUEN = "usaquen"


class Slot(BaseModel):
    starts_at: datetime
    minutes: int


class AvailabilityResponse(BaseModel):
    branch: Branch
    day: date
    slots: list[Slot]


app = FastAPI()


@app.get("/availability", response_model=AvailabilityResponse)
def availability(branch: Branch, day: date) -> AvailabilityResponse:
    slots = [
        Slot(starts_at=datetime.combine(day, time(hour, minute), BOGOTA), minutes=20)
        for hour in range(7, 19)
        for minute in (0, 20, 40)
    ]
    return AvailabilityResponse(branch=branch, day=day, slots=slots)
PYEOF
python3 - <<'EOF'
import ast, pathlib
src = pathlib.Path("app_duelo.py").read_text()
tree = ast.parse(src)
for n in ast.walk(tree):
    if isinstance(n,(ast.Module,ast.ClassDef,ast.FunctionDef)):
        if n.body and isinstance(n.body[0], ast.Expr) and isinstance(n.body[0].value, ast.Constant) and isinstance(n.body[0].value.value,str):
            n.body.pop(0)
print("FastAPI, solo el endpoint del duelo:", len([l for l in ast.unparse(tree).splitlines() if l.strip()]), "líneas")
EOF
(./.venv/bin/python -m uvicorn app_duelo:app --port 8126 --log-level error >/dev/null 2>&1 &) && sleep 5 && curl -s "http://127.0.0.1:8126/availability?branch=centro&day=2026-10-15" | python3 -c "import sys,json; d=json.load(sys.stdin); print('verificado:', len(d['slots']), 'espacios ·', d['slots'][0])" ; pkill -f "uvicorn app_duelo"

# --- 2026-09-13T03:59:33 · Build both container images
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

# --- 2026-09-13T04:00:02 · Measure container cold start
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

# --- 2026-09-13T04:00:51 · Clean up containers
docker rm -f duelo 2>/dev/null; docker ps -a --format "{{.Names}}" | head -3; echo "--- limpieza ---"

# --- 2026-09-13T04:09:37 · Measure the course volume to derive the bands
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
import pathlib, re
bloques = {"A": ["00-ambiente","01-modelo","02-secuencias","03-python","04-errores","05-shell","06-formatos"],
           "B": ["07-cuando","08-el-contrato","09-distribucion"],
           "C": ["10-fastapi","11-persistencia","12-django","13-integraciones","14-concurrencia","15-el-proceso","16-operacion","17-el-duelo"]}
total_pal = 0
for b, pre in bloques.items():
    pal = ej = 0
    for p in pre:
        f = next(pathlib.Path(".").glob(f"{p}*.md"))
        t = f.read_text()
        pal += len(t.split())
        m = re.search(r"## 🧪 8\. Ejercicios \((\d+)\)", t)
        ej += int(m.group(1)) if m else 0
    total_pal += pal
    print(f"Bloque {b}: {len(pre)} fases · {pal:,} palabras · {ej} ejercicios · lectura ≈ {pal/200/60:.1f} h")
print(f"\nTOTAL: {total_pal:,} palabras · lectura ≈ {total_pal/200/60:.1f} h a 200 palabras/minuto")
PYEOF

# --- 2026-09-13T04:10:09 · Update the root documents with real bands and links
python3 - <<'PYEOF'
import io

# --- 0-ESTRUCTURA-CURSO.md: las bandas, ya calculables ---
p = "0-ESTRUCTURA-CURSO.md"; s = io.open(p, encoding="utf-8").read()
old = """El curso publica **bandas de dedicación por bloque**, no horas por fase. Una tabla de horas por
fase que nadie puede cumplir desprestigia al resto del documento, y aquí el tiempo real lo domina
el encargo, no la lectura: dos personas con el mismo material tardan lo mismo leyendo y muy
distinto construyendo.

Las bandas se calculan cuando las 18 fases estén escritas y se publican aquí. Lo único que se
puede decir hoy con base: **cada miniproyecto está calibrado entre dos y cinco horas**, y son
dieciocho."""
new = """El curso publica **bandas de dedicación por bloque**, no horas por fase. Una tabla de horas por
fase que nadie puede cumplir desprestigia al resto del documento, y aquí el tiempo real lo domina
el encargo, no la lectura: dos personas con el mismo material tardan lo mismo leyendo y muy
distinto construyendo.

Las bandas están calculadas sobre el material ya escrito, y conviene decir **de dónde salen**
porque eso es lo que permite ajustarlas a tu ritmo:

| Bloque | Fases | Lectura | Miniproyectos | Ejercicios (un tercio) | **Banda** |
|---|---|---|---|---|---|
| **A** · el script | 7 | 4.6 h | 14–35 h | ~19 h | **40–60 h** |
| **B** · la frontera | 3 | 1.9 h | 6–15 h | ~8 h | **15–25 h** |
| **C** · la aplicación | 8 | 4.8 h | 16–40 h | ~22 h | **45–65 h** |
| **Total** | 18 | **11.4 h** | 36–90 h | ~49 h | **100–150 h** |

La lectura es un número medido: 137.000 palabras a 200 por minuto. Los miniproyectos salen de su
calibración —entre dos y cinco horas cada uno— y los ejercicios suponen que haces **uno de cada
tres** de los 450, a unos veinte minutos. **Si los haces todos, suma otras cien horas**; si no
haces ninguno, resta cuarenta y nueve y el curso sigue funcionando, aunque bastante peor.

> 📝 **Lo que estas bandas no capturan:** el tiempo que pasas peleando con algo que no entiendes,
> que es donde de verdad se aprende y que no se puede estimar. Tómalas como el piso, no como el
> presupuesto."""
assert old in s; s = s.replace(old, new)
io.open(p, "w", encoding="utf-8").write(s); print("ok estructura")

# --- README.md: los enlaces que ahora existen ---
p = "README.md"; s = io.open(p, encoding="utf-8").read()
old2 = """Empieza por [`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md), sigue con
[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md) y después con la Fase 00."""
new2 = """Empieza por [`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md), sigue con
[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md) y después con la Fase 00.

Calcula entre **100 y 150 horas** para el camino base completo; el desglose por bloque, con su
derivación, está en el documento de estructura.

Y si quieres ver de qué se trata antes de empezar, dos atajos: **[`BENCHMARKS.md`](BENCHMARKS.md)**
tiene las dieciocho mediciones del curso con sus veredictos —incluidos los cinco empates— y
**[`INSTINTOS.md`](INSTINTOS.md)** tiene los dieciocho reflejos de Java que el material recalibra,
con lo que cuesta cada uno."""
assert old2 in s; s = s.replace(old2, new2)
io.open(p, "w", encoding="utf-8").write(s); print("ok readme")
PYEOF
ls -la *.md && echo "--- total del curso ---" && cat *.md | wc -l | xargs echo "líneas:" && du -sh . 

# --- 2026-09-13T04:10:23 · Check which patch applied
grep -n "bandas se calculan\|Banda\b\|100–150" 0-ESTRUCTURA-CURSO.md | head; echo "---README---"; grep -n "BENCHMARKS\|INSTINTOS" README.md | head

# --- 2026-09-13T04:10:27 · Inspect the exact text to replace
sed -n '248,262p' 0-ESTRUCTURA-CURSO.md | cat -A | sed 's/\$$//' | head -20; echo "=== crudo ==="; sed -n '248,262p' 0-ESTRUCTURA-CURSO.md

# --- 2026-09-13T04:10:43 · Apply the band table and the links
python3 - <<'PYEOF'
import io

p = "0-ESTRUCTURA-CURSO.md"; s = io.open(p, encoding="utf-8").read()
old = """Las bandas se calculan cuando las 18 fases estén escritas y se publican aquí. Lo único que se
puede decir hoy con base: **cada miniproyecto está calibrado entre dos y cinco horas**, y son
dieciocho."""
new = """Las bandas están calculadas sobre el material ya escrito, y conviene decir **de dónde salen**,
porque eso es lo que te permite ajustarlas a tu ritmo:

| Bloque | Fases | Lectura | Miniproyectos | Ejercicios (un tercio) | **Banda** |
|---|---|---|---|---|---|
| **A** · el script | 7 | 4.6 h | 14–35 h | ~19 h | **40–60 h** |
| **B** · la frontera | 3 | 1.9 h | 6–15 h | ~8 h | **15–25 h** |
| **C** · la aplicación | 8 | 4.8 h | 16–40 h | ~22 h | **45–65 h** |
| **Total** | 18 | **11.4 h** | 36–90 h | ~49 h | **100–150 h** |

La lectura es un número medido: **137.000 palabras** a 200 por minuto. Los miniproyectos salen de
su calibración —entre dos y cinco horas cada uno—, y la columna de ejercicios supone que haces
**uno de cada tres** de los 450, a unos veinte minutos. Si los haces todos, suma otras cien horas;
si no haces ninguno, resta cuarenta y nueve y el curso sigue funcionando, aunque bastante peor.

> 📝 **Lo que estas bandas no capturan** es el tiempo que vas a pasar peleando con algo que no
> entiendes, que es donde de verdad se aprende y que no se puede estimar. Tómalas como el piso, no
> como el presupuesto."""
assert old in s, "estructura"
io.open(p, "w", encoding="utf-8").write(s.replace(old, new)); print("ok estructura")

p = "README.md"; s = io.open(p, encoding="utf-8").read()
old2 = "Empieza por [`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md), sigue con"
assert old2 in s, "readme no encontrado"
bloque = s[s.index(old2):]
fin = bloque.index("\n\n")
viejo = bloque[:fin]
nuevo = viejo + """

Calcula entre **100 y 150 horas** para el camino base completo; el desglose por bloque, con su
derivación, está en el documento de estructura.

Y si quieres ver de qué se trata antes de empezar, dos atajos:
**[`BENCHMARKS.md`](BENCHMARKS.md)** tiene las dieciocho mediciones del curso con sus veredictos
—incluidos los cinco empates— y **[`INSTINTOS.md`](INSTINTOS.md)** tiene los dieciocho reflejos de
Java que el material recalibra, con lo que cuesta cada uno."""
io.open(p, "w", encoding="utf-8").write(s.replace(viejo, nuevo)); print("ok readme")
PYEOF
grep -n "100–150\|BENCHMARKS" 0-ESTRUCTURA-CURSO.md README.md | head

# --- 2026-09-13T04:10:59 · Final structural and link check
echo "=== estructura de las 18 fases ===" && python3 - <<'PYEOF'
import pathlib, re
fases = sorted([p for p in pathlib.Path(".").glob("*.md")
                if re.match(r"^(0[0-9]|1[0-7])-", p.name)],
               key=lambda p: p.name)
ok = True
for f in fases:
    t = f.read_text()
    secciones = len(re.findall(r"^## ", t, re.M))
    tag = len(re.findall(r"git tag -a fase-", t))
    ej = re.search(r"## 🧪 8\. Ejercicios \((\d+)\)", t)
    med = "## 📏 6" in t
    mini = "## 🧱 7" in t
    pend = "📌 Pendientes" in t
    estado = "✓" if (secciones == 11 and tag == 1 and ej and med and mini and pend) else "✗"
    if estado == "✗": ok = False
    print(f" {estado} {f.name:<42} secciones={secciones} tag={tag} ej={ej.group(1) if ej else '—'} 📏={med} 🧱={mini} 📌={pend}")
print("\nTODAS CONFORMES" if ok else "\nHAY FASES NO CONFORMES")
PYEOF
echo; echo "=== enlaces internos rotos ===" && python3 - <<'PYEOF'
import pathlib, re
existentes = {p.name for p in pathlib.Path(".").glob("*.md")}
rotos = 0
for f in pathlib.Path(".").glob("*.md"):
    for destino in re.findall(r"\]\((?!http)([^)#]+\.md)\)", f.read_text()):
        if destino not in existentes:
            print(f"  {f.name} -> {destino}"); rotos += 1
print("  ninguno" if not rotos else f"  {rotos} rotos")
PYEOF
echo; echo "=== inventario ==="; ls *.md | wc -l | xargs echo "documentos:"; ls src/*/ -d | wc -l | xargs echo "directorios en src/:"; du -sh . | cut -f1 | xargs echo "tamaño:"

# --- 2026-09-13T04:11:08 · List the sections of Fase 17
grep -n "^## " 17-el-duelo-y-el-veredicto.md

# --- 2026-09-13T04:11:20 · Verify section count and clean up images
python3 - <<'PYEOF'
import pathlib, re
t = pathlib.Path("17-el-duelo-y-el-veredicto.md").read_text()
# quita bloques de código antes de contar
sin_codigo = re.sub(r"```.*?```", "", t, flags=re.S)
print("Fase 17, secciones reales:", len(re.findall(r"^## ", sin_codigo, re.M)))
print("  = 10 de la plantilla + §6.b (el veredicto, exigido por la propuesta) + 📌 Pendientes")
PYEOF
docker rmi -f aurea-fastapi aurea-spring >/dev/null 2>&1; echo "imágenes del duelo borradas"; docker images --format "{{.Repository}}" | grep -c aurea || echo "  quedan 0"; du -sh /tmp/claude-501 | cut -f1 | xargs echo "scratchpad:"

# --- 2026-09-13T04:32:59 · Read the optional topics inventory
cat prompts/propuestas-temas-opcionales.md

# --- 2026-09-13T04:33:48 · Verify ORM and text library names on PyPI
for p in pony peewee tortoise-orm sqlmodel piccolo-orm ormar gino masonite-orm pypika aiosql records dataset pygments rich textual jinja2 mako chameleon markdown-it-py mistune docutils; do v=$(curl -s "https://pypi.org/pypi/$p/json" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['info']['version'], (d['urls'][0]['upload_time'][:10] if d['urls'] else '?'))" 2>/dev/null); echo "$p -> ${v:-NO EXISTE}"; done

# --- 2026-09-13T04:34:10 · Verify multimedia, comms and testing library names
for p in piccolo yagmail aiosmtpd paramiko pysftp locust testcontainers factory-boy freezegun respx polyfactory nox tox mutmut playwright moviepy imageio av ffmpeg-python mediapipe face-recognition insightface rembg manim pygame arcade svgwrite drawsvg graphviz networkx cookiecutter copier questionary typer click tqdm; do v=$(curl -s "https://pypi.org/pypi/$p/json" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['info']['version'], (d['urls'][0]['upload_time'][:10] if d['urls'] else '?'))" 2>/dev/null); printf "%-18s %s\n" "$p" "${v:-NO EXISTE}"; done

# --- 2026-09-13T04:38:46 · Check prefix collisions
grep -oE '\b(ia|cd|ui|ar|au|db|or|tx|cl|co|vz|qa|cv|ed|pk|jv)[0-9]{2}\b' prompts/propuestas-fases-base-ia-datos.md 2>/dev/null | sed 's/[0-9]*$//' | sort -u | tr '\n' ' '; echo; echo "--- prefijos que usa el archivo de IA/datos ---"; grep -oE '^\| ?[a-z]{2}[0-9]{2}' prompts/propuestas-fases-base-ia-datos.md | sed 's/[^a-z]//g' | sort -u | tr '\n' ' '; echo; echo "--- tamaño del inventario nuevo ---"; wc -l prompts/propuestas-temas-opcionales.md | awk '{print $1" líneas"}'; grep -c "^| " prompts/propuestas-temas-opcionales.md | xargs echo "filas de tabla:"

# --- 2026-09-13T04:49:32 · Inspect prompts docs and phase-count mentions
cd prompts && ls -la *.md && echo "=== dónde aparece el conteo de fases ===" && grep -n "18 fases\|dieciocho\|18 prompts\|las 18\|de 18" *.md ../*.md 2>/dev/null | head -30

# --- 2026-09-13T04:49:44 · Count phase files and read current optional doc structure
cd .. && ls -1 [0-9]*.md | cat -n && echo "=== secciones del documento opcional (estado actual) ===" && grep -n "^## " prompts/propuestas-temas-opcionales.md

# --- 2026-09-13T04:52:23 · Read the middle of the current optional doc
sed -n '140,340p' prompts/propuestas-temas-opcionales.md

# --- 2026-09-13T04:52:28 · Read the end of the current optional doc
sed -n '440,600p' prompts/propuestas-temas-opcionales.md

# --- 2026-09-13T04:52:32 · Read remaining sections
sed -n '474,520p;517,600p' prompts/propuestas-temas-opcionales.md | head -120; echo "=== FIN ==="; tail -40 prompts/propuestas-temas-opcionales.md

# --- 2026-09-13T04:52:45 · Diagnose the document damage
cd prompts && wc -l propuestas-temas-opcionales.md && echo "=== todos los encabezados ===" && grep -n "^#\{2,3\} " propuestas-temas-opcionales.md && echo "=== líneas duplicadas consecutivas ===" && awk 'prev==$0 && NF>0 {print NR": "$0} {prev=$0}' propuestas-temas-opcionales.md | head -20

# --- 2026-09-13T04:53:10 · Read the intro and nomenclature sections
sed -n '1,30p;69,125p' propuestas-temas-opcionales.md

# --- 2026-09-13T04:53:50 · Add the à la carte framing
python3 - <<'PYEOF'
import io, re
p = "propuestas-temas-opcionales.md"
s = io.open(p, encoding="utf-8").read()

# ─── 1. El encuadre "a la carta", al frente de todo ───
old = """> **Estado del camino base: escrito.** Las 18 fases, `BENCHMARKS.md` e `INSTINTOS.md` están
> publicados. Este documento es el inventario del material que viene **después**, y se revisa con
> el mismo criterio de forma: sin apéndices, un miniproyecto por fase, una medición por fase."""
new = """> **Estado del camino base: escrito.** Las 18 fases —numeradas 00 a 17—, `BENCHMARKS.md` e
> `INSTINTOS.md` están publicados. Este documento es el inventario del material que viene
> **después**.

## 🍽️ Qué es esto: material **a la carta**

Y conviene decirlo antes que nada, porque cambia el criterio con el que se lee todo lo demás.

**El camino base es un curso: se recorre en orden, de la Fase 00 a la 17, y cada fase depende de
la anterior.** Esto no. Esto es una **carta**: secciones **totalmente opcionales**, que se leen
sueltas, cuando el lector necesita un tutorial concreto de una herramienta y quiere un ejemplo que
corra y un ejercicio que lo fije.

De ahí salen cuatro consecuencias, y las cuatro son distintas del camino base:

- **No hay tope de tamaño.** Cien secciones están bien. Doscientas también. Una carta larga no es
  un problema: es una carta larga. Lo que sí sería un problema es una sección que no se pueda leer
  sola.
- **Cada sección se sostiene por sí misma.** No se asume que el lector hizo la anterior del mismo
  track. El orden dentro de un track es una **sugerencia de lectura**, no una dependencia.
- **No todo tiene que pasar por Áurea.** El camino base construye software para una empresa
  ficticia y esa disciplina es lo que lo hace defendible. Aquí, en cambio, el objetivo es **dar el
  sabor de una capacidad de Python** con un ejemplo concreto: si el ejemplo natural de `turtle` es
  dibujar una espiral, se dibuja una espiral, y nadie tiene que inventar por qué una clínica
  odontológica necesita tortugas.
- **Y por eso Áurea decide la prioridad, no la admisión.** Lo que encaja con el dominio se escribe
  primero, porque le sirve al lector el lunes y porque hereda un contexto ya montado. Lo demás se
  escribe al final, y se escribe igual de bien.

> 🧭 **La regla de forma de una sección a la carta:** un ejemplo que corre, un ejercicio concreto,
> y la honestidad de siempre —si hay una afirmación comparativa, lleva su número; si una biblioteca
> está abandonada, se dice—. **Lo que no se le exige es miniproyecto ni medición obligatoria**: eso
> es del camino base, donde hay un sistema que construir. Aquí el entregable es que el lector
> entienda de qué es capaz la herramienta y sepa si le sirve.

⚠️ **El riesgo de este formato, declarado:** una carta de doscientas secciones sueltas es un
catálogo, y un catálogo envejece y no enseña. Lo que lo salva es que cada sección responda a *qué
problema resuelve esta herramienta y cuándo no usarla* — que es el criterio del curso entero,
aplicado a una pieza pequeña."""
assert old in s; s = s.replace(old, new)

# ─── 2. Los tres puntos de "qué cambia", ajustados a la nueva numeración ───
old = """1. **Los archivos se llaman distinto.** Todo lo opcional pasa a `op-<tt>NN-<slug>.md`
   —`op-ui02-gradio.md`— para que el material opcional quede en **un solo bloque alfabético**
   detrás del camino base, en vez de repartido entre dieciséis prefijos sueltos. Es una
   divergencia declarada respecto del `CLAUDE.md` del repositorio, y va argumentada en la §2."""
new = """1. **Los archivos se llaman distinto.** Todo lo opcional pasa a `opNNN-<tt>NN-<slug>.md`
   —`op014-ui02-gradio.md`— para que el material opcional quede en **un solo bloque** detrás del
   camino base, **ordenado por el número global de tres dígitos** en vez de por el azar alfabético
   de sus dos letras. Es una divergencia declarada respecto del `CLAUDE.md` del repositorio, y va
   argumentada en la §2."""
assert old in s; s = s.replace(old, new)
io.open(p, "w", encoding="utf-8").write(s)
print("ok: encuadre a la carta + nota de numeración")
PYEOF

# --- 2026-09-13T04:54:11 · Reframe the criterion section
python3 - <<'PYEOF'
import io
p = "propuestas-temas-opcionales.md"
s = io.open(p, encoding="utf-8").read()

# ─── §1: el criterio deja de decidir admisión y pasa a decidir prioridad ───
old = """## 1. El criterio: qué es núcleo y qué es opcional

Cuatro preguntas, y basta que falle la primera para mandar un tema al material opcional:"""
new = """## 1. El criterio: qué es núcleo, qué es carta, y en qué orden se escribe

Hay **dos** criterios distintos y conviene no confundirlos, porque la versión anterior de este
documento los mezclaba y eso descartaba temas que no había por qué descartar.

**El primero decide qué entra al camino base.** Son cuatro preguntas, y basta que falle la primera
para que el tema salga del curso obligatorio:"""
assert old in s; s = s.replace(old, new)

old = """Los temas opcionales no se marcan uno a uno: se agrupan en **tracks con tesis propia**, cada uno
con su prefijo de archivo y su espacio de tags, según la convención del `CLAUDE.md` del
repositorio."""
new = """**El segundo decide el orden en que se escribe la carta**, y no es el mismo. Una vez que un tema
está fuera del camino base, ya no hay nada que "aprobar": si alguien quiere saber cómo se dibuja
con `turtle` o cómo se habla con Cassandra desde Python, esa sección tiene derecho a existir. Lo
único que se decide es **cuándo se escribe**, y ahí manda una sola pregunta:

> 🧭 **¿Le sirve a Áurea?** Si el tema tiene un encargo creíble en el dominio del curso, se escribe
> primero: el lector lo va a usar el lunes, y la sección hereda un contexto que ya está montado y
> que no hay que inventar. Si no lo tiene, se escribe igual — al final, con su propio ejemplo, sin
> forzar a la clínica a necesitar algo que no necesita.

**Y una prioridad de segundo orden, para desempatar:** entre dos temas que Áurea no usa, va antes
el que recalibre un reflejo de Java —los ORMs, los modelos de datos no relacionales— y después el
que solo enseñe una API que se lee bajo demanda.

Los temas opcionales se agrupan en **tracks con tesis propia**, cada uno con su token de dos
letras y su espacio de tags. El agrupamiento es para orientarse; **la unidad real es la sección
suelta**, que es como se va a leer."""
assert old in s; s = s.replace(old, new)

# el punto 3 del criterio, que era el que descartaba lo no-Áurea
old = """3. **¿Alimenta a un proyecto del curso?** Si no alimenta después a un servicio, sobra o está mal
   planteado."""
new = """3. **¿Alimenta a un proyecto del curso?** Si no alimenta después a un servicio, no es del camino
   base. *(Ojo: esto lo saca del curso obligatorio, **no** lo descalifica para la carta — es la
   confusión que la versión anterior de este documento cometía.)*"""
assert old in s; s = s.replace(old, new)
io.open(p, "w", encoding="utf-8").write(s)
print("ok: §1 separa admisión de prioridad")
PYEOF

# --- 2026-09-13T04:54:17 · Read the current criterion section
sed -n '/^## 1\. El criterio/,/^## 2\./p' propuestas-temas-opcionales.md | head -40

# --- 2026-09-13T04:54:47 · Reframe the criterion section
python3 - <<'PYEOF'
import io
p = "propuestas-temas-opcionales.md"
s = io.open(p, encoding="utf-8").read()

reemplazos = [
("""## 1. El criterio: qué es núcleo y qué es opcional

Cuatro preguntas, y basta que falle la primera para mandar un tema al material opcional:""",
"""## 1. El criterio: qué es núcleo, qué es carta, y en qué orden se escribe

Hay **dos** criterios distintos y conviene no confundirlos, porque la versión anterior de este
documento los mezclaba y eso descartaba temas que no había por qué descartar.

**El primero decide qué entra al camino base.** Cuatro preguntas, y basta que falle la primera
para que el tema salga del curso obligatorio:"""),

("""3. **¿Alimenta a un proyecto del curso?** Si no alimenta después a un servicio, sobra o está mal
   planteado.""",
"""3. **¿Alimenta a un proyecto del curso?** Si no alimenta después a un servicio, no es del camino
   base. *(Ojo: eso lo saca del curso obligatorio, **no** lo descalifica para la carta — es la
   confusión que la versión anterior de este documento cometía.)*"""),

("""4. **¿Se puede enseñar como modelo de acceso en vez de como producto?** Es el principio rector del
   repositorio, y es el que decide si un tema con nombre comercial merece una fase: *Cassandra* es
   un producto; *"columnar ancho, sin joins, modelado por consulta"* es un modelo. La primera
   formulación no entra; la segunda sí.

Los temas opcionales no se marcan uno a uno: se agrupan en **tracks con tesis propia**, cada uno
con su prefijo de archivo y su espacio de tags. La forma exacta de esos nombres —y por qué diverge
de la convención del `CLAUDE.md` del repositorio— está en la §2.""",
"""4. **¿Se puede enseñar como modelo de acceso en vez de como producto?** Es el principio rector del
   repositorio, y es el que decide si un tema con nombre comercial merece una **fase del camino
   base**: *Cassandra* es un producto; *"columnar ancho, sin joins, modelado por consulta"* es un
   modelo. En la carta esta pregunta se relaja, y la §6 explica en qué se convierte.

**El segundo criterio decide el orden en que se escribe la carta**, y no es el mismo. Una vez que
un tema está fuera del camino base ya no hay nada que "aprobar": si alguien quiere saber cómo se
dibuja con `turtle` o cómo se le habla a Cassandra desde Python, esa sección tiene derecho a
existir. Lo único que se decide es **cuándo se escribe**, y ahí manda una sola pregunta:

> 🧭 **¿Le sirve a Áurea?** Si el tema tiene un encargo creíble en el dominio del curso, se escribe
> primero: el lector lo va a usar el lunes, y la sección hereda un contexto ya montado que no hay
> que inventar. Si no lo tiene, se escribe igual — al final, con su propio ejemplo, y sin forzar a
> una clínica odontológica a necesitar algo que no necesita.

**Y un desempate de segundo orden:** entre dos temas que Áurea no usa, va antes el que recalibre un
reflejo de Java —los ORMs, los modelos de datos no relacionales, la concurrencia nativa— y después
el que solo enseñe una API que se puede leer bajo demanda.

Los temas de la carta se agrupan en **tracks con tesis propia**, cada uno con su token de dos
letras y su espacio de tags. El agrupamiento sirve para orientarse; **la unidad real es la sección
suelta**, que es como se va a leer. La forma exacta de los nombres —y por qué diverge de la
convención del `CLAUDE.md` del repositorio— está en la §2."""),

("""> ⚠️ **Y una regla que este documento aprendió del camino base:** un track que sea un **desfile de
> bibliotecas** no vale nada. Cada fase mide lo mismo sobre el mismo problema, o el track se
> convierte en una lista de enlaces que el lector podía haber buscado solo. Cuando abajo aparezca
> una lista larga de nombres, es **inventario del terreno**, no el índice del capítulo: el
> capítulo elige tres, los mide, y enlaza el resto.""",
"""> ⚠️ **Y una regla que este documento aprendió del camino base:** una sección que sea un **desfile
> de bibliotecas** no vale nada. Cuando abajo aparezca una lista larga de nombres, es **inventario
> del terreno, no el índice del capítulo**: la sección elige una o dos, las hace correr, y enlaza
> el resto. Un catálogo se puede buscar solo; lo que el lector no puede buscar solo es *cuál de
> estas sirve para lo suyo y cuándo no usarla*."""),
]

for old, new in reemplazos:
    assert old in s, old[:70]
    s = s.replace(old, new)
io.open(p, "w", encoding="utf-8").write(s)
print("ok: §1 reencuadrada")
PYEOF

# --- 2026-09-13T04:54:54 · Read the naming section tail
sed -n '/^## 2\. 🔤/,/^### 2.1/p' propuestas-temas-opcionales.md | tail -50

# --- 2026-09-13T04:55:22 · Rewrite the naming convention to 3 digits
python3 - <<'PYEOF'
import io
p = "propuestas-temas-opcionales.md"
s = io.open(p, encoding="utf-8").read()

s = s.replace("## 2. 🔤 La nomenclatura: `op-<tt>NN-<slug>.md`",
              "## 2. 🔤 La nomenclatura: `opNNN-<tt>NN-<slug>.md`")

old = """La convención que este documento adopta es una sola letra más, y lo arregla entero:

```text
op-<tt><NN>-<slug>.md
 │    │   │     └── el tema, en español, minúsculas, con guiones
 │    │   └──────── número de dos dígitos, empezando en 01 dentro de cada track
 │    └──────────── las dos letras del track: ui, ar, db, wf…
 └───────────────── literal, siempre, para todo lo opcional
```

Y el listado pasa a ser este:

| Archivo | Qué es |
|---|---|
| `00-ambiente-editores-y-ecosistema.md` … `17-el-duelo-y-el-veredicto.md` | El camino base, intacto y contiguo |
| `op-ar01-binario-de-verdad.md` … `op-ar11-el-pegamento-o-el-binario.md` | Track de archivos, entero y junto |
| `op-au01-http-contra-sistemas-ajenos.md` … | Track de automatización |
| `op-db01-el-panorama-y-el-db-api.md` … | Track de modelos de acceso |
| `op-ui02-gradio.md` | La fase suelta que el lector busca por nombre |

**Tres propiedades que se ganan y que justifican el cambio:**

- **Un solo bloque.** Todo lo opcional queda contiguo y *después* del camino base, porque `0`–`9`
  ordenan antes que cualquier letra. El curso obligatorio se lee de arriba abajo sin ruido.
- **Los tracks no se entrelazan.** Dentro del bloque `op-`, cada track es un tramo continuo.
  `ls op-db*` es el track de datos completo; `ls op-*01-*` es la primera fase de cada track, que
  es exactamente lo que alguien mira para elegir por dónde entrar.
- **El filtro es trivial en todas partes.** `op-*` en `ls`, en `git tag -l`, en un `.gitignore` de
  borrador, en la barra del editor y en el índice del `README`. Tres caracteres hacen el trabajo
  que si no hay que hacer enumerando dieciséis prefijos, uno por uno, en cada sitio."""

new = """La convención que este documento adopta lo arregla entero, y añade lo que una **carta** necesita
y un conjunto de tracks sueltos no da: **un número de plato**.

```text
op<NNN>-<tt><NN>-<slug>.md
 │  │      │   │     └── el tema, en español, minúsculas, con guiones
 │  │      │   └──────── dos dígitos dentro del track, desde 01
 │  │      └──────────── las dos letras del track: ui, ar, db, wf…
 │  └─────────────────── tres dígitos: el número de la sección en la carta completa
 └────────────────────── literal, siempre, para todo lo opcional
```

**El número de tres dígitos es el orden de la carta**, y se asigna **en el orden en que las
secciones se escriben**, no por track. Así `op001-` es la primera sección que existió, y una
sección nueva de cualquier track se numera con el siguiente libre. Tres dígitos dan **hasta 999
secciones**, que es holgura de sobra para una carta que puede crecer indefinidamente.

Y el listado pasa a ser este:

| Archivo | Qué es |
|---|---|
| `00-ambiente-editores-y-ecosistema.md` … `17-el-duelo-y-el-veredicto.md` | El camino base, intacto y contiguo |
| `op001-db01-el-panorama-y-el-db-api.md` | La primera sección de la carta que se escribió |
| `op002-db02-postgres-desde-python.md` | La segunda |
| `op014-ui02-gradio.md` | La sección suelta que el lector busca por nombre |
| `op057-ed01-turtle.md` | Una de las últimas: sin encargo de Áurea, y escrita igual |

**Cuatro propiedades que se ganan y que justifican el cambio:**

- **Un solo bloque.** Todo lo opcional queda contiguo y *después* del camino base, porque `0`–`9`
  ordenan antes que cualquier letra. El curso obligatorio se lee de arriba abajo sin ruido.
- **El orden del listado es el orden de la carta**, y no el azar alfabético de dos letras. `ls
  op*` devuelve las secciones en el orden en que se publicaron, que para material a la carta es
  más útil que agruparlas por track — el lector que vuelve quiere ver **qué hay de nuevo**.
- **El track sigue siendo filtrable.** `ls op*-db*` es el track de datos completo, esté donde esté
  su numeración global; `ls op*-*01-*` es la primera sección de cada track, que es lo que mira
  quien busca por dónde entrar.
- **Y el filtro grueso es trivial en todas partes.** `op*` en `ls`, en `git tag -l`, en un
  `.gitignore` de borrador, en la barra del editor y en el índice del `README`.

⚠️ **El costo, dicho entero:** el número global **no se puede deducir** del track ni del tema — hay
que consultarlo antes de crear un archivo, y si dos secciones se escriben en paralelo hay que
desempatar a mano. Es el precio de tener orden de publicación en el nombre. La alternativa
—numerar por track y ordenar alfabéticamente— no tiene ese costo y pierde lo que la carta
necesita. **Se acepta el costo, y la mitigación es un renglón en este documento:** la siguiente
sección libre es la **`op001`**, porque todavía no se ha escrito ninguna."""
assert old in s; s = s.replace(old, new)
io.open(p, "w", encoding="utf-8").write(s)
print("ok: §2 con numeración de tres dígitos")
PYEOF

# --- 2026-09-13T04:55:28 · Read sections 2.1 and 2.2
sed -n '/^### 2.1 Lo que arrastra/,/^## 3\./p' propuestas-temas-opcionales.md | head -45

# --- 2026-09-13T04:55:54 · Align the tags and divergence sections
python3 - <<'PYEOF'
import io
p = "propuestas-temas-opcionales.md"
s = io.open(p, encoding="utf-8").read()

reemplazos = [
("""**El código.** Cada fase con código usa el mismo nombre que su documento, como en el camino base:
`src/op-ui02-gradio/`, `src/op-db06-columnar-ancho/`. La regla del repositorio —el directorio se
llama exactamente como el archivo que lo acompaña— se mantiene, solo cambia el nombre.""",
"""**El código.** Cada sección con código usa el mismo nombre que su documento, como en el camino
base: `src/op014-ui02-gradio/`, `src/op001-db01-el-panorama-y-el-db-api/`. La regla del
repositorio —el directorio se llama exactamente como el archivo que lo acompaña— se mantiene."""),

("""**Los tags de git.** El camino base usa `fase-NN` y `mini-NN`. Lo opcional lleva su track y su
`op-` delante:

```bash
git tag -a op-ui-fase-02 -m "op ui02 cerrada: …"
git tag -a op-ui-mini-02 -m "op ui02 mini: … (medición: …)"
```

Con eso, `git tag -l 'fase-*'` sigue siendo el índice limpio del camino base —que es la razón por
la que el `CLAUDE.md` del repositorio pide espacios de nombres separados— y `git tag -l 'op-*'`
es el índice de todo lo opcional. `git tag -l 'op-ui-*'` es un track.

**Los commits.** Mismo criterio, con el prefijo delante: `op ui02: …` para el cuerpo,
`op ui02 ej07: …` para ejercicios, `op ui02 mini: …` para el miniproyecto.""",
"""**Los tags de git.** El camino base usa `fase-NN` y `mini-NN`. Lo opcional lleva su track y su
`op-` delante, **sin el número global**: el tag identifica la sección dentro de su track, que es
como se la nombra en prosa.

```bash
git tag -a op-ui-fase-02 -m "op ui02 cerrada: …"
```

Con eso, `git tag -l 'fase-*'` sigue siendo el índice limpio del camino base —que es la razón por
la que el `CLAUDE.md` del repositorio pide espacios de nombres separados—, `git tag -l 'op-*'` es
el índice de toda la carta, y `git tag -l 'op-ui-*'` es un track.

> 📝 **Por qué el tag no lleva el número global** aunque el archivo sí: el número de la carta es un
> **orden de publicación**, y un tag es una **identidad**. Si algún día hay que reordenar la carta
> —fusionar dos secciones, insertar una— los archivos se renombran y los tags no deberían moverse.
> Separarlos evita ese acoplamiento.

**Los commits.** Mismo criterio, con el prefijo delante: `op ui02: …` para el cuerpo y
`op ui02 ej07: …` para ejercicios. **El `mini:` no aplica por defecto**: el miniproyecto es del
camino base, y una sección de la carta lo lleva solo si el tema lo pide."""),

("""**Los identificadores en prosa.** Dentro de este documento y de las tablas de fases, una fase se
sigue nombrando `ui02`, `db06`, `wf03` — corto y legible. El `op-` es del **archivo**, no del
nombre de la fase. En el texto se escribe el nombre completo solo cuando se está hablando de
archivos.""",
"""**Los identificadores en prosa.** Dentro de este documento y de las tablas, una sección se sigue
nombrando `ui02`, `db06`, `wf03` — corto, legible y estable. **El `opNNN-` es del archivo**, no del
nombre de la sección; en el texto se escribe el nombre completo solo cuando se habla de archivos.
Esa separación es deliberada: el número de la carta puede cambiar y el identificador no."""),

("""| | Convención del repositorio | Convención de este curso |
|---|---|---|
| Fases opcionales | `beNN-name.md` | `op-<tt>NN-<slug>.md` |
| Apéndices | `bea-NN-topic.md` | **No aplica** — el curso no tiene apéndices |
| Tags | `be-fase-<slug>` | `op-<tt>-fase-NN`, `op-<tt>-mini-NN` |""",
"""| | Convención del repositorio | Convención de este curso |
|---|---|---|
| Material opcional | `beNN-name.md` | `opNNN-<tt>NN-<slug>.md` |
| Apéndices | `bea-NN-topic.md` | **No aplica** — el curso no tiene apéndices |
| Tags | `be-fase-<slug>` | `op-<tt>-fase-NN` |"""),

("""solo token ya separa las dos épocas. Este curso propone **dieciséis, y con los tracks nuevos de la
§17 son veinticinco**; con tantos tokens sueltos el prefijo deja de separar y empieza a mezclar. El
`op-` recupera la propiedad que la convención original buscaba —que el camino base se liste
limpio— a costa de tres caracteres por archivo.""",
"""solo token ya separa las dos épocas. Este curso propone **veinticinco tracks** y una carta que
puede crecer sin tope; con tantos tokens sueltos el prefijo deja de separar y empieza a mezclar. El
`opNNN-` recupera la propiedad que la convención original buscaba —que el camino base se liste
limpio— y añade la que una carta necesita: **orden de publicación**, a costa de seis caracteres por
archivo."""),
]

for old, new in reemplazos:
    assert old in s, old[:60]
    s = s.replace(old, new)
io.open(p, "w", encoding="utf-8").write(s)
print("ok: §2.1 y §2.2 alineadas")
PYEOF

# --- 2026-09-13T04:56:05 · Rename track headers to the token form
python3 - <<'PYEOF'
import io, re
p = "propuestas-temas-opcionales.md"
s = io.open(p, encoding="utf-8").read()
antes = len(re.findall(r"`op-[a-z]{2}NN-`", s))
s = re.sub(r"^(#{2,3} [\d.]+ )`op-([a-z]{2})NN-` — ", r"\1Track `\2` — ", s, flags=re.M)
s = re.sub(r"^(#{2,3} [\d.]+ )`op-([a-z]{2})NN-` ", r"\1Track `\2` ", s, flags=re.M)
io.open(p, "w", encoding="utf-8").write(s)
print(f"encabezados con el patrón viejo: {antes} · restantes: {len(re.findall(r'`op-[a-z]{2}NN-`', s))}")
PYEOF
grep -n "^#\{2,3\} [0-9]" propuestas-temas-opcionales.md | sed -n '3,30p'

# --- 2026-09-13T04:56:15 · Read the db track section
sed -n '350,392p' propuestas-temas-opcionales.md

# --- 2026-09-13T04:57:03 · Reframe the db track around Python interaction
python3 - <<'PYEOF'
import io
p = "propuestas-temas-opcionales.md"
s = io.open(p, encoding="utf-8").read()

old = """## 6. Track `db` — Modelos de acceso a datos

> **Tesis, reformulada:** **¿qué modelo de acceso tiene tu dominio?** No es un catálogo de
> motores: es el recorrido por las formas de guardar y consultar que existen, con el criterio para
> reconocer cuál pide tu problema — y la admisión de que en el 80% de los casos la respuesta sigue
> siendo Postgres.

Esta es la reformulación que hace entrar a Cassandra y compañía (§1.1). El track **no** enseña
productos: enseña modelos, y usa un producto representativo por modelo para que haya código que
correr.

| Fase | Modelo de acceso | Representantes | La pregunta que contesta |
|---|---|---|---|
| db01 | **El panorama y el DB-API 2.0** | drivers, `sqlite3`, `psycopg` | Qué es un driver y qué te está resolviendo |
| db02 | **Relacional, otros motores** | MySQL/MariaDB, SQL Server, Oracle | Qué cambia de verdad al mover el SQL de sitio |
| db03 | **Embebido y analítico local** | SQLite, **DuckDB**, LMDB, RocksDB, `diskcache` | Cuándo no hace falta un servidor |
| db04 | **Documental** | MongoDB (PyMongo, Beanie), CouchDB | Cuándo el esquema flexible paga, y cuándo se cobra |
| db05 | **Clave-valor** | Valkey/Redis, etcd, DynamoDB | Caché, colas, límites de tasa, sesiones |
| db06 | **Columnar ancho** | **Cassandra/ScyllaDB**, HBase, Bigtable | Modelar **por consulta** en vez de por entidad, y vivir sin joins |
| db07 | **Grafo** | Neo4j, Memgraph, ArangoDB | Cuando la relación es el dato: la red de aliados de Áurea |
| db08 | **Serie de tiempo** | TimescaleDB, InfluxDB, QuestDB | Agregación por ventana, retención, *downsampling* |
| db09 | **Vectorial y búsqueda** | pgvector, Qdrant, Milvus, OpenSearch, Meilisearch, Typesense | Similitud contra coincidencia exacta |
| db10 | **Objetos y archivos** | S3/MinIO, `boto3`, `fsspec` | Cuándo el "registro" es un archivo |
| db11 | **Bitácora de eventos** | Kafka, Redpanda, NATS JetStream | Cuando el hecho es el dato y el estado es una proyección |
| db12 | ⚖️ Veredicto: **el árbol de decisión de modelos de acceso**, y por qué Postgres gana casi siempre |

> 🧭 **La fase que sostiene el track es `db06`**, y no por Cassandra: porque **modelar por consulta
> en vez de por entidad** es un giro mental de verdad para alguien con once años de tercera forma
> normal. El reflejo que ataca es real, es caro, y no se corrige leyendo.

> ⚖️ **Y el veredicto tiene que ser incómodo:** Postgres hace hoy documental (`jsonb`), vectorial
> (pgvector), serie de tiempo (Timescale), búsqueda (`tsvector`) y cola (`SKIP LOCKED`)
> razonablemente bien. **El track existe para enseñar cuándo eso deja de alcanzar**, y la respuesta
> honesta es "más tarde de lo que la gente cree". Si `db12` no dice eso, el track se convirtió en
> publicidad.

📝 **Cambio respecto a la versión anterior:** los ORMs alternativos salen de aquí y se van a su
propio track (§7), porque son una pregunta distinta —cómo hablarle a la base desde Python— y
porque solos dan para un track corto con tesis propia."""

new = """## 6. Track `db` — Hablarle a cada sistema de datos **desde Python**

> **Tesis:** **cómo se conecta, se consulta y se escribe desde Python en cada sistema concreto.**
> No es un curso de bases de datos ni un seminario sobre modelos de acceso: es el ejemplo que
> corre. Qué biblioteca se instala, cómo se abre la conexión, cómo se ve una consulta, qué devuelve
> y en qué tipos de Python, y cuál es la trampa que ese sistema tiene reservada para quien llega
> de Postgres.

Esto es lo que hace entrar a Cassandra y compañía (§1.1), y conviene decir con precisión **qué
clase de sección es** cada una, porque la versión anterior de este documento prometía otra cosa:

| Lo que **no** es | Lo que **sí** es |
|---|---|
| Enseñar Cassandra | Enseñar `cassandra-driver`: sesión, `prepare`, consistencia, `paging`, y qué te devuelve en tipos de Python |
| Un seminario sobre modelado de datos | Un ejemplo corriendo y un ejercicio, con la advertencia de qué se rompe si modelas como en Postgres |
| Elegir tu motor de producción | Saber qué se siente cada uno desde el código, para poder opinar con fundamento |

> 📝 **Qué pasó con el "modelo de acceso".** La versión anterior organizaba el track como un
> recorrido por modelos de acceso, y era una idea defendible — pero es **material del camino base**,
> no de la carta: ahí es donde se enseña a decidir. Aquí el lector ya decidió, o solo tiene
> curiosidad, y lo que necesita es **ver el código**. El modelo de acceso se menciona en una línea
> por sección, como contexto de por qué ese sistema se usa así; no es el contenido.

| Sección | Sistema | Desde Python con… | La trampa para quien viene de Postgres |
|---|---|---|---|
| db01 | **El panorama y el DB-API 2.0** | `sqlite3`, `psycopg` | Qué es un driver, qué te resuelve, y qué es `paramstyle` |
| db02 | **MySQL / MariaDB** | `mysqlclient`, `PyMySQL`, `asyncmy` | El modo estricto, la colación, y `utf8` que no es UTF-8 |
| db03 | **SQL Server y Oracle** | `pyodbc`, `pymssql`, `oracledb` | El driver del sistema operativo, y que `pyodbc` necesita algo instalado fuera de Python |
| db04 | **SQLite a fondo** | `sqlite3` de la caja | WAL, tipos dinámicos, y el bloqueo de escritor único (Fase 06 del camino base) |
| db05 | **DuckDB** | `duckdb` | Que consulta Parquet y CSV directamente, y que no es un reemplazo de Postgres |
| db06 | **Clave-valor: Valkey/Redis** | `redis-py` | Que todo es bytes, la caducidad, y que `KEYS` en producción es un incidente |
| db07 | **Documental: MongoDB** | `pymongo`, Beanie | Sin joins de verdad, el documento de 16 MB, y el índice que creías que existía |
| db08 | **Columnar ancho: Cassandra / ScyllaDB** | `cassandra-driver` | **Modelar por consulta**: sin joins, sin `ORDER BY` libre, y la clave de partición decide todo |
| db09 | **Grafo: Neo4j** | `neo4j`, `py2neo` | Cypher, y que el recorrido barato es el que el modelo previó |
| db10 | **Serie de tiempo: TimescaleDB e InfluxDB** | `psycopg` / `influxdb-client` | Ventanas, retención y *downsampling* como primitivas |
| db11 | **Vectorial: pgvector y Qdrant** | `pgvector`, `qdrant-client` | Similitud no es igualdad: el índice es aproximado y eso está bien |
| db12 | **Búsqueda: OpenSearch, Meilisearch, Typesense** | sus clientes | Análisis de texto, y que el índice es una estructura aparte que hay que alimentar |
| db13 | **Objetos: S3 / MinIO** | `boto3`, `fsspec` | Que no hay directorios, y que listar cuesta |
| db14 | **Bitácora de eventos: Kafka / NATS** | `confluent-kafka`, `nats-py` | El desplazamiento, los grupos de consumidores, y que "leer" no borra |
| db15 | ⚖️ Cierre: **el árbol de decisión**, y por qué Postgres gana casi siempre |

> 🧭 **Si de este track solo se escriben tres secciones**, que sean `db06` (Valkey), `db07`
> (MongoDB) y `db08` (Cassandra): las dos primeras porque Áurea las va a usar de verdad —caché y
> documentos—, y la tercera porque **modelar por consulta en vez de por entidad** es el único giro
> mental del track que un senior de Postgres no puede intuir.

> ⚖️ **Y el cierre tiene que ser incómodo:** Postgres hace hoy documental (`jsonb`), vectorial
> (pgvector), serie de tiempo (Timescale), búsqueda (`tsvector`) y cola (`SKIP LOCKED`)
> razonablemente bien. **La carta existe para que sepas qué se siente cada alternativa**, no para
> venderlas: si `db15` no dice que Postgres gana casi siempre, el track se convirtió en publicidad.

⚠️ **El problema práctico de este track, declarado:** catorce sistemas son **catorce servicios que
levantar**. La regla para que sea escribible: **todo corre en contenedores, con un
`compose.yaml` por sección y datos de ejemplo que caben en segundos**, o la sección no se escribe.
Lo que no se puede pedir es que el lector monte un clúster.

📝 **Cambio respecto a la versión anterior:** los ORMs salen de aquí y se van a su propio track
(§7) — son otra pregunta: no *cómo le hablo a este sistema*, sino *qué capa pongo encima*."""
assert old in s; s = s.replace(old, new)
io.open(p, "w", encoding="utf-8").write(s)
print("ok: §6 reencuadrada a 'desde Python'")
PYEOF

# --- 2026-09-13T04:57:10 · Read the priority and open questions sections
sed -n '/^## 19\./,/^## 21\./p' propuestas-temas-opcionales.md | head -70

# --- 2026-09-13T04:58:03 · Rewrite priority as turns and update open questions
python3 - <<'PYEOF'
import io
p = "propuestas-temas-opcionales.md"
s = io.open(p, encoding="utf-8").read()
i = s.index("## 19. Prioridad sugerida")
j = s.index("## 21. Temas evaluados y descartados")

nuevo = """## 19. El orden de la carta: qué se escribe primero

**Ya no es un ranking de mérito, porque nada se descarta.** Es el orden en que se escribe, y lo
decide la pregunta de §1: **¿le sirve a Áurea?** Lo que tiene encargo en el dominio se escribe
primero —hereda un contexto ya montado y el lector lo usa el lunes—; lo demás se escribe después,
con su propio ejemplo, y se escribe igual de bien.

### 🥇 Primer turno — con encargo directo en Áurea

Estos tienen un problema concreto de la empresa esperándolos, y la sección se escribe casi sola
porque el contexto ya existe.

| Track | El encargo que lo justifica |
|---|---|
| `lg` — legado e intercambio | **RIPS, el XML de la DIAN, el export de Odontovía.** Es el trabajo de Patricia, literalmente |
| `au` — automatización | **Los portales de las aseguradoras no tienen API.** Está en la historia de la empresa, sin inventar nada |
| `co` — comunicaciones | Patricia manda las liquidaciones por correo; dos aseguradoras mandan archivos por FTP |
| `wf` — orquestación | Continuación directa de la Fase 15: el cierre nocturno ya existe y pide esto |
| `qa` — calidad y pruebas | El sistema tiene que sobrevivir tres años con un solo ingeniero. Es la tesis del curso |
| `ob` — observabilidad | El cierre corre a las 2:47 y alguien tiene que enterarse cuando falle |
| `se` — seguridad aplicada | La historia clínica es reservada. No es opcional en el dominio, solo en el temario |
| `tx` — texto y plantillas | Los reportes, los correos y el HTML que Áurea genera todos los meses |
| `ui` — interfaces sin frontend | Entregarle algo a Julián sin contratar un frontend. Absorbe `cl` |
| `db` — sistemas de datos | Parcial: Valkey y Mongo tienen caso; los otros doce son curiosidad legítima |
| `jv` — convivir con la JVM | **Odontovía es Java Swing sobre JBoss.** El sistema heredado no es hipotético |

### 🥈 Segundo turno — encargo real pero no urgente

| Track | Por qué espera |
|---|---|
| `so` — optimización y decisiones | La agenda de diez sedes **es** un problema de asignación, pero Áurea vive sin resolverlo |
| `or` — ORMs | El curso ya eligió SQLAlchemy y funciona; esto es ampliar el mapa |
| `vz` — visualización | El reporte del cierre puede llevar gráficos, y hoy no los lleva |
| `sy` — sistema operativo | Reemplaza scripts de shell que Áurea todavía no tiene |
| `pr` — protocolos y contratos | Hoy REST alcanza; el día que no alcance, esto es lo que hace falta |
| `pk` — gestores | La decisión ya se tomó en la Fase 07. Es mapa del terreno, no necesidad |

### 🥉 Tercer turno — sin encargo en Áurea, y escritos igual

Aquí es donde el encuadre **a la carta** hace su trabajo: estos temas no tienen que justificarse
ante una clínica odontológica. Se escriben con **su propio ejemplo**, el que la herramienta pide.

| Track | El ejemplo que usaría, sin pasar por Áurea |
|---|---|
| `ff` — frontera nativa | Acelerar un cálculo numérico cualquiera y medir el antes y el después |
| `ar` — archivos y multimedia | Convertir, recortar y recomponer archivos de muestra |
| `gi` — geoespacial | Un conjunto de datos abierto con coordenadas |
| `cv` — visión por computador | Rostros propios o sintéticos — y **nunca** fotografía clínica (§13) |
| `ed` — didáctica y juguetes | Una espiral con `turtle`, un juego de veinte líneas. **Y está bien que sea eso** |

> 🧭 **Lo que cambió respecto a la versión anterior de esta sección.** Antes esto era un ranking de
> 1 a 23 con dos tracks tachados —`cl` fusionado y `ed` eliminado—. **`ed` deja de estar
> eliminado:** en una carta no hay por qué eliminar un plato que alguien puede querer pedir. Baja
> al tercer turno, se escribe al final, y su sección de `turtle` dibuja una espiral sin pedirle
> permiso al dominio. La única fusión que se mantiene es `cl` dentro de `ui`, y esa es por
> solapamiento real de contenido, no por prioridad.

---

## 20. Lo que este inventario todavía no resuelve

Dos preguntas menos que antes: la de los prefijos la cierra la §2, y la de **cuántos tracks se
escriben** la cierra el encuadre a la carta — se escriben los que se alcancen, en el orden de la
§19, y la carta queda abierta. Quedan tres:

1. **¿El dominio de Áurea aguanta el primer turno completo?** Once tracks con encargo directo son
   muchos encargos. Algunos están sobrados de material (`lg`, `au`, `co`); otros van a competir por
   el mismo problema —`ob` y `qa` se solapan alrededor del cierre nocturno— y conviene repartirlos
   antes de escribir, no después.
2. **¿Qué se le exige a una sección de la carta?** El camino base pide medición y miniproyecto por
   fase. La §🍽️ dice que aquí **no** son obligatorios, y eso abre una pregunta de calidad que hay
   que contestar con un ejemplo: **la primera sección que se escriba fija el estándar** de qué es
   "un ejemplo que corre y un ejercicio concreto". Recomendación: que la primera sea del primer
   turno y con Áurea detrás, para que el listón quede alto.
3. **¿Quién verifica el estado de las bibliotecas, y cada cuánto?** La §18 retira cinco muertos
   confirmados y sospecha de otros seis sin verificar. Un inventario de este tamaño se pudre solo:
   o cada tabla lleva su fecha de verificación y un guion que la comprueba contra PyPI, o en un año
   este documento vuelve a recomendar código abandonado. **Recomendación: un
   `prompts/check-inventario.py` antes de escribir la primera sección.** Con una carta que puede
   llegar a cien secciones, esto deja de ser higiene y pasa a ser infraestructura.

---

"""
s = s[:i] + nuevo + s[j:]
io.open(p, "w", encoding="utf-8").write(s)
print("ok: §19 por turnos y §20 actualizada")
PYEOF
grep -n "^## " propuestas-temas-opcionales.md | tail -8 && wc -l propuestas-temas-opcionales.md

# --- 2026-09-13T04:58:11 · Find remaining elimination recommendations
grep -n "elimina\|se cae\|el más discutible\|ed05" propuestas-temas-opcionales.md | head -20

# --- 2026-09-13T04:58:14 · Read the ed recommendations in context
sed -n '693,705p;1018,1026p' propuestas-temas-opcionales.md

# --- 2026-09-13T04:58:32 · Fix the ed track recommendations
python3 - <<'PYEOF'
import io
p = "propuestas-temas-opcionales.md"
s = io.open(p, encoding="utf-8").read()

reemplazos = [
("## 14. Track `ed` — Didáctica, divulgación y juguetes **(el más discutible del inventario)**",
 "## 14. Track `ed` — Didáctica, divulgación y juguetes **(tercer turno: sin encargo en Áurea)**"),

("""> **Mi recomendación:** si hay que recortar el inventario, este track es el primero que se cae —
> **salvo `ed05`, que debería absorberse en `ui01` o en el track `cl`**, porque esa sí es una
> pregunta del curso.
>
> 🪦 **Y con los nueve tracks de la §17 sobre la mesa, la §17.10 ya no lo recomienda: lo propone
> eliminar.** El párrafo de arriba se deja escrito porque es el argumento que llevó a esa
> decisión, no porque siga abierta.""",
"""> 🪦 **Este track estuvo propuesto para eliminación, y el encuadre a la carta lo salva.** El
> argumento de arriba era correcto mientras el criterio de §1 decidía la **admisión**: con `lg` y
> `so` sobre la mesa, gastar una fase del curso en `turtle` no se sostenía. Pero en una carta no
> hay plazas que repartir — **no hay por qué eliminar un plato que alguien puede querer pedir**.
>
> **Lo que queda, entonces:** `ed` baja al **tercer turno** (§19) y se escribe al final, con su
> propio ejemplo y sin pasar por el dominio. `ed01` dibuja una espiral con `turtle` y no tiene que
> explicar por qué una clínica odontológica necesita tortugas.
>
> **Y `ed05` sí se muda**, pero no por debilidad: *enseñarle a alguien que no programa* es una
> pregunta del camino base —el curso se juega la tesis en si Patricia puede abrir lo que el lector
> escriba— y encaja mejor en `ui01`, junto a las demás formas de entregar. Que se mude es un
> ascenso, no un recorte."""),

("| `ed` — didáctica | **Se elimina**, salvo `ed05`, que se absorbe en `ui01`. Ya fallaba dos de las cuatro preguntas de §1; con `lg` y `so` en la mesa, ocupar sitio con `turtle` no se sostiene |",
 "| `ed` — didáctica | ~~Se elimina~~ → **revertido por el encuadre a la carta**: baja al tercer turno (§19) y se escribe al final, con ejemplo propio. `ed05` sí se muda a `ui01`, por afinidad y no por recorte |"),

("**Y a cambio, tres bajas que esta propuesta recomienda de frente:**",
 "**Y a cambio, tres ajustes que esta propuesta recomienda de frente** —uno de ellos revertido después por el encuadre a la carta:"),
]
for old, new in reemplazos:
    assert old in s, old[:60]
    s = s.replace(old, new)
io.open(p, "w", encoding="utf-8").write(s)
print("ok: ed deja de estar eliminado")
PYEOF
grep -c "" propuestas-temas-opcionales.md | xargs echo "líneas:"; grep -n "op-<tt>\|op-uiNN\|op-dbNN" propuestas-temas-opcionales.md | head

# --- 2026-09-13T04:58:48 · Read the headers of all prompts docs
for f in README.md propuesta-fases-y-alcance.md propuestas-fases-base-ia-datos.md prompts-de-fase.md prompts-documentos-raiz.md plantillas-de-capitulo.md formato-de-miniproyectos.md formato-de-mediciones.md guia-de-estilo-y-convenciones.md alcance-del-proyecto.md; do echo "───── $f"; head -8 "$f"; done

# --- 2026-09-13T04:59:16 · Add state banners to the prompts docs
python3 - <<'PYEOF'
import io

BANNER = """> ✅ **Estado: el camino base está escrito.** Las 18 fases (00–17), `BENCHMARKS.md` e
> `INSTINTOS.md` están publicados en la raíz del curso. Este documento pasa de ser **encargo** a
> ser **registro de lo que se decidió**: sigue mandando sobre cualquier revisión del camino base y
> sobre el material a la carta, pero ya no describe trabajo pendiente.
"""

# ───────── prompts/README.md ─────────
p = "README.md"; s = io.open(p, encoding="utf-8").read()
old = """> 🧭 **Estado: listo para escribir.** Las decisiones de estructura están cerradas, las 18 fases
> tienen su alcance detallado y su prompt. Lo que falta es redactar el curso."""
new = """> ✅ **Estado: el camino base está escrito.** Las **18 fases** —numeradas 00 a 17—,
> `BENCHMARKS.md` e `INSTINTOS.md` están publicados. Este directorio pasa de ser el **encargo** a
> ser el **registro de lo que se decidió y por qué**.
>
> **Lo que sigue** es el material **a la carta**: secciones opcionales, sueltas, que se leen cuando
> alguien necesita un tutorial concreto de una herramienta. Su inventario y su orden de escritura
> están en [`propuestas-temas-opcionales.md`](propuestas-temas-opcionales.md), y **no se rigen por
> las mismas reglas que el camino base** — no se les exige miniproyecto ni medición, y no tienen
> que pasar por el dominio de Áurea."""
assert old in s; s = s.replace(old, new)
io.open(p, "w", encoding="utf-8").write(s); print("ok README")

# ───────── propuesta-fases-y-alcance.md ─────────
p = "propuesta-fases-y-alcance.md"; s = io.open(p, encoding="utf-8").read()
old = """> **Estado: cerrado.** Las siete decisiones que estaban en discusión quedaron resueltas y
> están en §9 con su porqué y con lo que se descartó a cambio."""
new = """> ✅ **Estado: ejecutado.** Las 18 fases que este documento especifica **están escritas y
> publicadas** en la raíz del curso, con sus mediciones, sus miniproyectos y sus 450 ejercicios.
> Lo que sigue vale como **registro de las decisiones**: manda sobre cualquier revisión del camino
> base, y ya no describe trabajo pendiente. Donde el texto dice "se escribirá" o "se calculará",
> léase en pasado — y donde una previsión no se cumplió, está anotado.

> **Estado de las decisiones: cerrado.** Las siete que estaban en discusión quedaron resueltas y
> están en §9 con su porqué y con lo que se descartó a cambio."""
assert old in s; s = s.replace(old, new)

old = """| Calendario | **Bandas por bloque**, no horas por fase | Se calculan cuando las 18 fases estén escritas |"""
new = """| Calendario | **Bandas por bloque**, no horas por fase | ✅ Calculadas y publicadas en `0-ESTRUCTURA-CURSO.md`: **100–150 h** en total (A 40–60, B 15–25, C 45–65) |"""
assert old in s; s = s.replace(old, new)
io.open(p, "w", encoding="utf-8").write(s); print("ok propuesta-fases")

# ───────── prompts-de-fase.md ─────────
p = "prompts-de-fase.md"; s = io.open(p, encoding="utf-8").read()
old = """**Un chat, un archivo.** Cada fase se redacta en su propio chat y produce un único `.md`. Si un
chat no produce entregable, o sobra o se salió de alcance."""
new = BANNER + """>
> **Para qué sirve todavía:** para revisar una fase, para reescribir una que quedó floja, y como
> modelo del prompt que va a necesitar el material **a la carta** — que es más ligero y tiene su
> propio encuadre en `propuestas-temas-opcionales.md`.

**Un chat, un archivo.** Cada fase se redacta en su propio chat y produce un único `.md`. Si un
chat no produce entregable, o sobra o se salió de alcance."""
assert old in s; s = s.replace(old, new)
io.open(p, "w", encoding="utf-8").write(s); print("ok prompts-de-fase")

# ───────── prompts-documentos-raiz.md ─────────
p = "prompts-documentos-raiz.md"; s = io.open(p, encoding="utf-8").read()
old = """Tres documentos viven en la **raíz del curso**, no en `prompts/`, y **se escriben antes que
cualquier fase** porque las 18 fases los enlazan. Cada uno se redacta en su propio chat."""
new = BANNER + """>
> Los tres documentos que este archivo encarga —`0-ESTRUCTURA-CURSO.md`,
> `00-convencion-de-git-y-tags.md` y el `README.md`— **existen y están publicados**, y a ellos se
> sumaron después `BENCHMARKS.md` e `INSTINTOS.md`, que la Fase 17 consolidó.

Tres documentos viven en la **raíz del curso**, no en `prompts/`, y **se escribieron antes que
cualquier fase** porque las 18 fases los enlazan. Cada uno se redactó en su propio chat."""
assert old in s; s = s.replace(old, new)
io.open(p, "w", encoding="utf-8").write(s); print("ok prompts-raiz")
PYEOF

# --- 2026-09-13T04:59:25 · Read the next-step and bands sections
sed -n '/^## 11. 🚦 Siguiente paso/,$p' propuesta-fases-y-alcance.md; echo "=== §9.3 ==="; sed -n '/9.3 · Cerrada: bandas/,/^🪦 \*\*9.4/p' propuesta-fases-y-alcance.md

# --- 2026-09-13T04:59:50 · Update the next-step section to a record of what happened
python3 - <<'PYEOF'
import io
p = "propuesta-fases-y-alcance.md"; s = io.open(p, encoding="utf-8").read()

old = """tiempo real lo domina el encargo, no la lectura. Las bandas se calculan cuando las 18 fases
estén escritas, no antes: estimarlas ahora sería inventarlas."""
new = """tiempo real lo domina el encargo, no la lectura. Las bandas se calculan cuando las 18 fases
estén escritas, no antes: estimarlas ahora sería inventarlas.

> ✅ **Cumplido.** Con las 18 fases escritas, las bandas se derivaron de material medible —137.000
> palabras a 200 por minuto, 18 miniproyectos de 2–5 h, y un tercio de los 450 ejercicios— y se
> publicaron en `0-ESTRUCTURA-CURSO.md` con esa derivación a la vista: **A 40–60 h, B 15–25 h,
> C 45–65 h, total 100–150 h.**"""
assert old in s; s = s.replace(old, new)

i = s.index("## 11. 🚦 Siguiente paso")
nuevo = """## 11. ✅ Lo que se hizo, y lo que sigue

**El orden de escritura que este documento fijó se siguió, y funcionó.** Se deja registrado
porque la decisión de escribir fuera del orden numérico —las ⭐ de la tesis antes que el resto—
era la más discutible del plan y resultó acertada:

| Turno | Qué | Resultado |
|---|---|---|
| 1 | Los tres documentos de la raíz | Escritos. `00-convencion-de-git-y-tags.md` quedó enlazado por las 18 fases sin reexplicarse nunca |
| 2 | Fases **00** y **01** | Fijaron voz, registro y el CLI. La 01 estrenó la deuda 💸, que la 06 cobró |
| 3 | Fases **07** y **09** ⭐ | **La apuesta del plan.** Escribirlas antes obligó a congelar la forma del CLI en `contrato-del-cli.md`, y eso evitó reescribir el Bloque A |
| 4 | Resto del Bloque A (02–06) | La 02 construyó el arnés que usaron las quince fases siguientes |
| 5 | **08** y Bloque C (10–16) | Sin sorpresas de estructura |
| 6 | **17** + `BENCHMARKS.md` + `INSTINTOS.md` | El duelo contra Spring Boot 3.5.16 y los dos consolidados |

📝 **Lo que el plan no previó**, y quedó anotado en los 📌 de las fases: que el material
necesitaría un documento más —`contrato-del-cli.md`—, que casi todas las mediciones saldrían de
un portátil de ocho núcleos cuando el dominio tiene una máquina de dos, y que ejecutar el código
contradiría al texto media docena de veces. Esto último es lo mejor que le pasó al curso.

### Lo que sigue: el material **a la carta**

Los tracks opcionales se revisan ahora, y **con un criterio de forma distinto al que este
documento fijó para el camino base**. La diferencia está argumentada en
[`propuestas-temas-opcionales.md`](propuestas-temas-opcionales.md) y se resume así:

| | Camino base (este documento) | Material a la carta |
|---|---|---|
| Cómo se lee | En orden, con dependencias | Suelto, cuando hace falta |
| Miniproyecto | **Obligatorio**, uno por fase | Solo si el tema lo pide |
| Medición | **Obligatoria**, una por fase | Solo si hay algo que comparar |
| Dominio | **Siempre Áurea** | Áurea decide la **prioridad**, no la admisión |
| Tamaño | Cerrado: 18 fases | Abierto: puede llegar a cien secciones |
| Archivos | `NN-nombre.md` | `opNNN-<tt>NN-nombre.md` |

⚠️ **Y la regla que no cambia**, porque es la que hace creíble al curso entero: ninguna afirmación
comparativa sin su número, ninguna biblioteca recomendada sin mirar su fecha de última
publicación, y el empate se llama empate.
"""
s = s[:i] + nuevo
io.open(p, "w", encoding="utf-8").write(s)
print("ok: §9.3 y §11 actualizadas")
PYEOF
tail -5 propuesta-fases-y-alcance.md

# --- 2026-09-13T04:59:58 · Read the IA/data proposal structure
grep -n "^#\{1,3\} \|ia[0-9][0-9]\|cd[0-9][0-9]" propuestas-fases-base-ia-datos.md | head -40

# --- 2026-09-13T05:00:09 · Read the stale base-path section and the tail
sed -n '1,12p;69,75p;144,175p' propuestas-fases-base-ia-datos.md

# --- 2026-09-13T05:00:31 · Mark the stale base path as superseded
python3 - <<'PYEOF'
import io
p = "propuestas-fases-base-ia-datos.md"; s = io.open(p, encoding="utf-8").read()

old = """> Curso *Python para desarrolladores Java senior*. Estado: **propuesta en discusión**.
> Los temas opcionales viven en `propuestas-temas-opcionales.md`.
> La empresa ficticia se decide aparte (`historia-propuesta-*.md`); aquí los proyectos se
> describen **por registro**, y los nombres concretos son los de la propuesta 1."""
new = """> Curso *Python para desarrolladores Java senior*.
> Los temas opcionales viven en `propuestas-temas-opcionales.md`.

> ⚠️ **Este documento está parcialmente superado, y conviene saber qué parte.**
>
> | Sección | Estado |
> |---|---|
> | §1 El eje · §2 La frontera · §3 Los cuatro proyectos | ✅ **Vigentes.** Se cumplieron tal cual en el curso escrito |
> | **§4 Camino base — 21 fases** | 🪦 **Superada.** El camino base quedó en **18 fases (00–17)**, definidas en [`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md) §4, **y ya están escritas**. La tabla de §4 se conserva como registro de la propuesta anterior; **no es la numeración oficial** |
> | §5 Track IA · §6 Track Ciencia de datos | ✅ **Vigentes y pendientes de escribir.** Son material a la carta, y su orden de escritura sale de `propuestas-temas-opcionales.md` §19 |
>
> **Qué pasó entre las 21 y las 18:** cuatro fusiones deliberadas —funciones y objetos, tipado y
> pruebas, operación y rendimiento, el duelo y el veredicto—, documentadas con su porqué y su
> mitigación en `propuesta-fases-y-alcance.md` §9.1. Las cuatro se sostuvieron al redactar, y las
> tres que tenían riesgo declarado lo dicen en sus 📌.

> 📝 **Sobre la empresa ficticia:** ya no se decide aparte. **Es Áurea**
> (`historia-propuesta-2-aurea.md`), decisión cerrada, y los nombres concretos de este documento
> —que son los de la propuesta 1, Cordillera— hay que leerlos como genéricos por registro."""
assert old in s; s = s.replace(old, new)

old = "## 🟩 4. Camino base obligatorio — 21 fases"
new = """## 🪦 4. Camino base obligatorio — 21 fases *(superada: quedaron 18, y están escritas)*

> Se conserva como registro de la propuesta anterior. **La numeración oficial y el contenido real
> del camino base están en `propuesta-fases-y-alcance.md` §4 y en los archivos `00-`…`17-` de la
> raíz del curso.**"""
assert old in s; s = s.replace(old, new)

old = """**21 fases base + 17 de proyecto (IA y datos) + los tracks opcionales.** Ocho proyectos.
Solo el base es obligatorio; los tracks no se leen entre sí y se toman a la carta."""
new = """**Cuentas de la propuesta original:** 21 fases base + 17 de proyecto (IA y datos) + los tracks
opcionales, con ocho proyectos.

**Cuentas reales, hoy:** **18 fases base escritas** (00–17, con cuatro proyectos empresariales), y
**17 secciones de IA y datos pendientes** —`ia01`–`ia08` y `cd01`–`cd09`— que pasan a ser material
**a la carta**: se leen sueltas, no se leen entre sí, y su turno de escritura sale de
`propuestas-temas-opcionales.md` §19."""
assert old in s; s = s.replace(old, new)

old = """> convención de archivo: `op-ia01-el-modelo-de-acceso-de-un-llm.md`, `op-cd03-polars.md`, y sus
> tags en `op-ia-fase-NN` / `op-cd-fase-NN`."""
new = """> convención de archivo **con su número de carta de tres dígitos**:
> `op031-ia01-el-modelo-de-acceso-de-un-llm.md`, `op044-cd03-polars.md`, y sus tags en
> `op-ia-fase-NN` / `op-cd-fase-NN` —los tags **no** llevan el número global, por la razón de la
> §2.1 de ese documento—."""
assert old in s; s = s.replace(old, new)

s = s.replace("## 🤖 5. Track IA — `op-iaNN-` · 8 fases, 2 proyectos",
              "## 🤖 5. Track IA — `ia` · 8 secciones, 2 proyectos")
s = s.replace("## 📊 6. Track Ciencia de datos — `op-cdNN-` · 9 fases, 2 proyectos",
              "## 📊 6. Track Ciencia de datos — `cd` · 9 secciones, 2 proyectos")
io.open(p, "w", encoding="utf-8").write(s)
print("ok: propuestas-fases-base-ia-datos alineada")
PYEOF

# --- 2026-09-13T05:00:48 · Add à la carte notes to the format docs
python3 - <<'PYEOF'
import io

NOTA = """
> 🍽️ **Y qué aplica al material a la carta.** Las secciones opcionales
> (`propuestas-temas-opcionales.md`) **no** se rigen por este documento al pie de la letra: se leen
> sueltas, no construyen un sistema, y por eso {excepcion} Lo que sí heredan es el criterio de
> fondo —{fondo}—, que es lo que separa una sección útil de una entrada de catálogo.
"""

docs = {
"plantillas-de-capitulo.md": (
 "la plantilla de diez secciones es una guía y no un molde: una sección de la carta puede\n> resolverse con propósito, concepto, ejemplo que corre, ejercicio y cierre.",
 "no explicar lo que el lector ya sabe, y decir dónde se rompe cada analogía"),
"formato-de-miniproyectos.md": (
 "**el miniproyecto no es obligatorio** ahí: se incluye solo cuando el tema lo pide.",
 "si hay ejercicio, tiene criterios de aceptación verificables y no se resuelve copiando el texto"),
"formato-de-mediciones.md": (
 "**la medición no es obligatoria** ahí: se incluye solo cuando hay dos opciones que comparar.",
 "ninguna afirmación comparativa sin número, y el competidor bien configurado"),
}

for archivo, (excepcion, fondo) in docs.items():
    s = io.open(archivo, encoding="utf-8").read()
    # insertar tras la primera línea '---' del documento
    marca = "\n---\n"
    i = s.index(marca) + len(marca)
    s = s[:i] + NOTA.format(excepcion=excepcion, fondo=fondo) + s[i:]
    io.open(archivo, "w", encoding="utf-8").write(s)
    print("ok", archivo)
PYEOF
head -22 formato-de-mediciones.md | tail -10

# --- 2026-09-13T05:03:10 · 
python3 - <<'PYEOF'
import io, re

nuevos = {
"plantillas-de-capitulo.md": """> 🍽️ **Qué aplica al material a la carta.** Las secciones opcionales
> (`propuestas-temas-opcionales.md`) se leen sueltas y no construyen un sistema, así que **esta
> plantilla es para ellas una guía y no un molde**: una sección de la carta se resuelve con
> propósito, concepto, ejemplo que corre, ejercicio y cierre. Lo que sí heredan es el criterio de
> fondo —no explicarle al lector lo que ya sabe, y decir dónde se rompe cada analogía—, que es lo
> que separa una sección útil de una entrada de catálogo.
""",
"formato-de-miniproyectos.md": """> 🍽️ **Qué aplica al material a la carta.** En las secciones opcionales
> (`propuestas-temas-opcionales.md`) **el miniproyecto no es obligatorio**: se incluye solo cuando
> el tema lo pide, y lo normal es que baste un ejercicio. Lo que sí heredan es la regla de
> calibración —si el ejercicio se resuelve copiando el texto de la sección, está mal planteado— y
> la de los criterios de aceptación verificables.
""",
"formato-de-mediciones.md": """> 🍽️ **Qué aplica al material a la carta.** En las secciones opcionales
> (`propuestas-temas-opcionales.md`) **la medición no es obligatoria**: se incluye solo cuando hay
> dos opciones que de verdad compitan por el mismo encargo. Lo que sí heredan, sin excepción, son
> las reglas de honestidad de la sección 3: ninguna afirmación comparativa sin número, el
> competidor bien configurado, y el empate se llama empate.
""",
}

for archivo, nota in nuevos.items():
    s = io.open(archivo, encoding="utf-8").read()
    # localizar el bloque insertado (empieza por "> 🍽️" y termina en la línea de catálogo)
    i = s.index("> 🍽️")
    j = s.index("\n\n", i) + 1
    s = s[:i] + nota + s[j:]
    io.open(archivo, "w", encoding="utf-8").write(s)
    print("ok", archivo)
PYEOF
sed -n '1,20p' formato-de-miniproyectos.md

# --- 2026-09-13T05:03:14 · Show heads of style guide and scope docs
sed -n '1,25p' guia-de-estilo-y-convenciones.md; echo "=====ALCANCE====="; sed -n '1,25p' alcance-del-proyecto.md

# --- 2026-09-13T05:03:30 · Add state banners to scope and style guide
python3 - <<'PYEOF'
import io

# --- alcance-del-proyecto.md: banner de estado tras el callout 🧭 ---
s = io.open("alcance-del-proyecto.md", encoding="utf-8").read()
ancla = "> material de trabajo válido, pero **cuando contradigan a este documento, manda este**.\n"
banner = ancla + """
> ✅ **Estado (13/09/2026): el camino base está escrito.** Las **18 fases (00–17)** existen en la
> raíz del curso, junto con `0-ESTRUCTURA-CURSO.md`, `00-convencion-de-git-y-tags.md`,
> `BENCHMARKS.md` e `INSTINTOS.md`. Lo que sigue es **material a la carta**: secciones opcionales
> `opNNN-<tt>NN-<slug>.md` catalogadas en `propuestas-temas-opcionales.md`. Este documento pasa de
> ser un plan a ser el contrato de lo escrito: si una fase ya publicada lo contradice, se corrige
> aquí y se anota el porqué, no se reescribe la fase en silencio.
"""
assert s.count(ancla) == 1
s = s.replace(ancla, banner)
io.open("alcance-del-proyecto.md", "w", encoding="utf-8").write(s)
print("ok alcance")

# --- guia-de-estilo-y-convenciones.md: banner + nota a la carta antes de '## 1.' ---
g = io.open("guia-de-estilo-y-convenciones.md", encoding="utf-8").read()
ancla = "un proyecto.\n\n---\n"
nota = """un proyecto.

> ✅ **Estado (13/09/2026).** Esta guía ya no describe un curso por escribir: describe uno escrito.
> Las **18 fases (00–17)** están publicadas y son el mejor ejemplo de cada regla de abajo — ante una
> duda que el texto no resuelva, gana lo que hagan las fases ya redactadas, y la regla se corrige
> aquí después.

> 🍽️ **Y el material a la carta.** Las secciones opcionales
> (`propuestas-temas-opcionales.md`) siguen esta guía **completa en lo editorial** —voz, tuteo,
> código en inglés con comentarios en español, analogías con su límite, ninguna comparación sin
> número— y **la relajan en lo estructural**: no llevan plantilla de diez secciones, ni miniproyecto
> obligatorio, ni medición obligatoria, ni las 25 ejercicios de una fase. Tampoco tienen que pasar
> por Áurea: una sección de la carta puede usar su propio ejemplo si le sirve mejor al tema. Las que
> sí aterrizan en Áurea son las que se escriben primero.

---
"""
assert g.count(ancla) == 1
g = g.replace(ancla, nota, 1)
io.open("guia-de-estilo-y-convenciones.md", "w", encoding="utf-8").write(g)
print("ok guia")
PYEOF
grep -rn "🍽️\|✅ \*\*Estado" *.md | cut -c1-90

# --- 2026-09-13T05:03:35 · Check for stale phase counts and old naming
grep -rn "17 fases\|21 fases\|20 fases\|op-ia\|op-cd\|op-xx" *.md | cut -c1-120; echo "--- naming opNNN ---"; grep -rho "op[0-9]\{3\}-[a-z]\{2\}[0-9]\{2\}-[a-z-]*" *.md | sort -u | head -12

# --- 2026-09-13T05:03:39 · Show lines around stale naming
sed -n '253,262p' propuestas-temas-opcionales.md

# --- 2026-09-13T05:03:43 · Fix stale track file naming reference
python3 - <<'PYEOF'
import io
f="propuestas-temas-opcionales.md"
s=io.open(f,encoding="utf-8").read()
old="""> [`propuestas-fases-base-ia-datos.md`](propuestas-fases-base-ia-datos.md) — `op-ia01-…`,
> `op-cd01-…`—"""
new="""> [`propuestas-fases-base-ia-datos.md`](propuestas-fases-base-ia-datos.md) — `op031-ia01-…`,
> `op042-cd01-…`—"""
assert s.count(old)==1
io.open(f,"w",encoding="utf-8").write(s.replace(old,new))
print("ok")
PYEOF
grep -n "op042-cd01\|op044-cd03" *.md

