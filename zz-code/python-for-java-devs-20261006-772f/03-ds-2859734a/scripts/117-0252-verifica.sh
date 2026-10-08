# rescatado de la sesión 2859734a, 2026-09-14T02:52:33Z · Investigate the two real defects
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "=== ia05: de dónde sale 'extract' ==="; grep -n "^from\|^import" ia05-normarag/test_normarag.py | head
echo "--- ¿lo dice su README? ---"; grep -n "extract\|ia02\|PYTHONPATH\|pytest" ia05-normarag/README.md | head
echo; echo "=== ia01: las dos pruebas que fallan ==="; grep -n "def test_" ia01-el-modelo-de-acceso-de-un-llm/test_failures.py
echo "--- ¿qué dice su README? ---"; grep -n "pytest\|sin red\|API" ia01-el-modelo-de-acceso-de-un-llm/README.md | head
