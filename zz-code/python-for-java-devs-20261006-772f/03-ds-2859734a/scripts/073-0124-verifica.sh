# rescatado de la sesión 2859734a, 2026-09-14T01:24:23Z · Full test sweep of the ds track
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== pruebas de todo el track ds ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds04-embudo src/ds07-scikit-learn; do
  printf "  %-40s" "$(basename $d)"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done
printf "  %-40s" "ds05-visualizacion"; (cd src/ds05-visualizacion && uv run --python 3.14 --with pytest --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds06-notebooks"; (cd src/ds06-notebooks-y-reproducibilidad && timeout 400 uv run --python 3.14 --with pytest --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' python -m pytest -q -p no:warnings 2>&1|tail -1)
