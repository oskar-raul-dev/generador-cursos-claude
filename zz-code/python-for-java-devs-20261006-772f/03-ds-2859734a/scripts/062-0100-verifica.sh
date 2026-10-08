# rescatado de la sesión 2859734a, 2026-09-14T01:00:22Z · List the non-I001 violations across the published src
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
uvx ruff@0.16.7 check src/ --output-format concise 2>&1 | grep -v "I001" | sed 's/:.*\] / /' | awk '{print $1}' | sort | uniq -c | sort -rn
echo "--- detalle ---"
uvx ruff@0.16.7 check src/ --output-format concise 2>&1 | grep -v "I001"
