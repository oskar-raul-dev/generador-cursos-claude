# rescatado de la sesión 2859734a, 2026-09-13T21:53:24Z · Run end-to-end and main benchmarks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python bench_punta_a_punta.py --datos data 2>&1 | tail -8
echo "=== y la tabla principal, con los seis tamaños en su sitio ==="
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python bench_engines.py --datos data 2>&1 | tail -18
