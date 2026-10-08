# rescatado de la sesión 2859734a, 2026-09-14T02:15:37Z · Fix ds08 lint and verify both directions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
uvx ruff@0.16.7 check --fix src/ds08-ausentismo >/dev/null 2>&1
uvx ruff@0.16.7 check src/ds0* && echo "lint OK desde la raíz"
(cd src/ds08-ausentismo && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "lint OK desde dentro" || uvx ruff@0.16.7 check . 2>&1 | tail -20)
