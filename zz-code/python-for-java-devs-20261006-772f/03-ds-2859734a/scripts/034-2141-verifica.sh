# rescatado de la sesión 2859734a, 2026-09-13T21:41:57Z · Re-run both measurements on the corrected dataset
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python bench_vectorized.py --filas 1000 10000 100000 1000000 5000000 2>&1 | grep -v "^Entorno\|^Pauta" | tail -32
echo "### ejercicio 16"; uv run --python 3.14 --with 'numpy==2.5.3' python ejercicio_16_lento.py --filas 2000000 | tail -1
echo "### ds02"; cd ../ds02-pandas && uv run --python 3.14 --with 'pandas==3.0.5' python bench_merge.py --datos data 2>&1 | tail -9
