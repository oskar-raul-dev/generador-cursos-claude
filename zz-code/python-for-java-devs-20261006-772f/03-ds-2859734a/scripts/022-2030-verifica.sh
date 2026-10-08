# rescatado de la sesión 2859734a, 2026-09-13T20:30:35Z · Lint and retest ds02
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
uvx ruff@0.16.7 check --fix . >/dev/null 2>&1; uvx ruff@0.16.7 check . && echo "LINT OK"
uv run --python 3.14 --with 'pandas==3.0.5' --with pytest python -m pytest -q 2>&1 | tail -3
