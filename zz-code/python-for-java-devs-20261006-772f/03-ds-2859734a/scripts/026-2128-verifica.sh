# rescatado de la sesión 2859734a, 2026-09-13T21:28:47Z · Restore in-directory import ordering
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds07-scikit-learn; do
  (cd $d && uvx ruff@0.16.7 check --fix . >/dev/null 2>&1; printf "  %-42s" "$d"; uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "OK (desde dentro, que es como lo corre el lector)" || echo FALLA)
done
