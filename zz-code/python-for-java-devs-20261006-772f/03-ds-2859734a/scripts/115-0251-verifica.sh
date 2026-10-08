# rescatado de la sesión 2859734a, 2026-09-14T02:51:49Z · Run the ia track test suites after the code edits
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in ia0*/; do
  printf "  %-46s" "$(basename $d)"
  (cd $d && timeout 300 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' --with 'pydantic==2.13.5' --with 'tenacity==9.1.4' python -m pytest -q 2>&1 | tail -1)
done
