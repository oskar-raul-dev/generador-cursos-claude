# rescatado de la sesión 2859734a, 2026-09-13T21:28:54Z · Final test run and cleanup
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds07-scikit-learn; do printf "%-42s " "$d"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' python -m pytest -q 2>&1 | tail -1); done
find . -name __pycache__ -type d -prune -exec rm -rf {} + 2>/dev/null; rm -rf ds01-numpy-y-el-modelo-vectorizado/data ds02-pandas/data
cd .. && rm -rf .pytest_cache && ls src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn
