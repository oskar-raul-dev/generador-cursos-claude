# rescatado de la sesión 2859734a, 2026-09-14T02:15:29Z · Lint the track after ds08
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
rm -rf src/ds0*/data src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
echo "=== lint ==="; uvx ruff@0.16.7 check src/ds0* 2>&1 | tail -6
for d in src/ds0*/; do printf "  %-46s" "$(basename $d)"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "OK" || echo "FALLA"); done
