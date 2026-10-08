# rescatado de la sesión 2859734a, 2026-09-14T02:53:10Z · Run the ia suites with all pinned dependencies
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "=== recuento final de pruebas, track por track ==="
total=0
for d in ia0*/; do
  n=$(cd $d && timeout 300 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' --with 'pydantic==2.13.5' --with 'tenacity==9.1.4' --with 'psycopg[binary]==3.3.5' --with 'pgvector==0.5.0' --with 'pypdf==6.18.1' python -m pytest -q 2>&1 | tail -1)
  printf "  %-46s %s\n" "$(basename $d)" "$n"
done
