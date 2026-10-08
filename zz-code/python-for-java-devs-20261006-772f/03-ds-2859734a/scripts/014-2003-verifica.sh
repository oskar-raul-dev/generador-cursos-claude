# rescatado de la sesión 2859734a, 2026-09-13T20:03:49Z · Apply ruff fixes
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
uvx ruff@0.16.7 check --fix src/ds01-numpy-y-el-modelo-vectorizado src/ds07-scikit-learn 2>&1 | tail -20
echo "--- SIM113 restante ---"
uvx ruff@0.16.7 check src/ds01-numpy-y-el-modelo-vectorizado src/ds07-scikit-learn 2>&1 | tail -20
