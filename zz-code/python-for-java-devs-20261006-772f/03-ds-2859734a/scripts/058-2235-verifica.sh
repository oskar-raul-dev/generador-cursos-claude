# rescatado de la sesión 2859734a, 2026-09-13T22:35:14Z · Lint with the course's documented ruff selection
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "=== con la selección que documenta la Fase 00 (E,F,I,UP,B) ==="
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds03-polars-y-el-modelo-lazy ds04-embudo ds07-scikit-learn; do
  printf "  %-42s" "$d"; (cd $d && uvx ruff@0.16.7 check --select E,F,I,UP,B --line-length 100 --target-version py314 . >/dev/null 2>&1 && echo OK || echo FALLA)
done
echo "=== y las suites ==="
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds03-polars-y-el-modelo-lazy ds04-embudo ds07-scikit-learn; do
  printf "  %-42s" "$d"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done
