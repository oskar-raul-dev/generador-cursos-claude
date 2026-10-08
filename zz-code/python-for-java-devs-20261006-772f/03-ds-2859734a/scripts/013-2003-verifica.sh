# rescatado de la sesión 2859734a, 2026-09-13T20:03:44Z · Show full lint output and config
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
cat ruff.toml 2>/dev/null || echo "(sin ruff.toml en la raíz del curso)"
uvx ruff@0.16.7 check src/ds01-numpy-y-el-modelo-vectorizado src/ds07-scikit-learn 2>&1 | head -40
