# rescatado de la sesión 2859734a, 2026-09-13T21:27:43Z · Final verification of the ds track
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== suites completas del track ds ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn; do
  printf "%-42s " "$d"
  (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' python -m pytest -q 2>&1 | tail -1)
done
echo "=== lint ==="; uvx ruff@0.16.7 check src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn && echo OK
echo "=== limpieza ==="; git status --short . | head
