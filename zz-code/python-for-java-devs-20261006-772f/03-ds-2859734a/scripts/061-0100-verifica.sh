# rescatado de la sesión 2859734a, 2026-09-14T01:00:08Z · Check whether the base course quotes the offending line
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "processed_keys.clear()" 13-integraciones.md src/13-integraciones/socio_falible.py
echo "=== ¿qué más del camino base falla con la config del curso? ==="
uvx ruff@0.16.7 check src/ 2>&1 | grep -E "^--> |  --> " | grep -v "ds0" | sort | uniq -c | head
