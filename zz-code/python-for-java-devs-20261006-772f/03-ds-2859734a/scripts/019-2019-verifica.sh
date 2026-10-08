# rescatado de la sesión 2859734a, 2026-09-13T20:19:44Z · Measure slow script and baseline at 2M rows
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python ejercicio_16_lento.py --filas 2000000 | tail -2
echo "--- referencia: el bucle honesto a 2M ---"
uv run --python 3.14 --with 'numpy==2.5.3' python bench_vectorized.py --filas 2000000 --repeticiones 3 2>&1 | tail -6
