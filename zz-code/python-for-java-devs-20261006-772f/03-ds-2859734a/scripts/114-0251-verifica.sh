# rescatado de la sesión 2859734a, 2026-09-14T02:51:24Z · Autofix the rest and see what remains
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
uvx ruff@0.16.7 check --fix src/ >/dev/null 2>&1
echo "=== lo que queda ==="; uvx ruff@0.16.7 check src/ --output-format concise
