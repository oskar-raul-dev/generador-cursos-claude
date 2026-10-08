# rescatado de la sesión 2859734a, 2026-09-14T02:53:30Z · Run ia05 with its documented PYTHONPATH
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ia05-normarag
echo "=== ia05 con el PYTHONPATH que su README documenta ==="
PYTHONPATH=../ia01-el-modelo-de-acceso-de-un-llm:../ia02-salida-estructurada:../ia04-embeddings-y-busqueda-semantica \
 timeout 300 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' --with 'pydantic==2.13.5' --with 'tenacity==9.1.4' --with 'psycopg[binary]==3.3.5' --with 'pgvector==0.5.0' --with 'pypdf==6.18.1' python -m pytest -q 2>&1 | tail -2
