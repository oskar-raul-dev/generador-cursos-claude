# rescatado de la sesión 2859734a, 2026-09-13T21:46:38Z · Verify all suites after the data correction
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds07-scikit-learn; do printf "%-42s " "$d"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' python -m pytest -q 2>&1|tail -1); done
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds07-scikit-learn; do printf "lint %-38s" "$d"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo OK || echo FALLA); done
