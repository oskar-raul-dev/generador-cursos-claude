# rescatado de la sesión 2859734a, 2026-09-14T02:52:12Z · Diagnose the ia failures
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "=== ia04 ==="; (cd ia04-embeddings-y-busqueda-semantica && timeout 200 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' python -m pytest -q 2>&1 | grep -E "Error|error" | head -3)
echo "=== ia05 ==="; (cd ia05-normarag && timeout 200 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' --with 'pydantic==2.13.5' python -m pytest -q 2>&1 | grep -E "Error|error" | head -3)
echo "=== ia01 ==="; (cd ia01-el-modelo-de-acceso-de-un-llm && timeout 200 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' python -m pytest -q 2>&1 | grep -E "^FAILED|Error" | head -4)
