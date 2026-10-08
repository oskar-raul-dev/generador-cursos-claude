# rescatado de la sesión 2859734a, 2026-09-13T21:28:26Z · Reconcile ruff import ordering across working directories
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
uvx ruff@0.16.7 check --fix src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn >/dev/null 2>&1
echo "desde la raíz del curso:"; uvx ruff@0.16.7 check src/ds0* && echo "  OK"
echo "desde dentro de cada dir:"
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn; do printf "  %-42s" "$d"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo OK || echo "FALLA"); done
