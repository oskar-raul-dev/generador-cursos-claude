# rescatado de la sesión 2859734a, 2026-09-13T21:56:26Z · Confirm DuckDB imports pandas when present
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
echo "--- entorno con solo duckdb ---"
uv run --python 3.14 --with 'duckdb==1.5.5' python -c "
import sys, duckdb; print('pandas cargado:', 'pandas' in sys.modules, '· polars:', 'polars' in sys.modules)"
echo "--- entorno con duckdb + pandas + polars ---"
uv run --python 3.14 --with 'duckdb==1.5.5' --with 'pandas==3.0.5' --with 'polars==1.44.2' python -c "
import sys, duckdb; print('pandas cargado:', 'pandas' in sys.modules, '· polars:', 'polars' in sys.modules)"
