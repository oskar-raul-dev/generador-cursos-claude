# rescatado de la sesión 2859734a, 2026-09-14T02:44:44Z · Grep correctly for external references
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== 1. Otros cursos del proyecto ==="
grep -rniE "go-for-java-devs|c-sharp-for-java|csharp|curso hermano|curso de C#|angular|docker-container|cursos-algoritmos|propuestas-cursos|_oskar|ruta-nosql|otro curso|los demás cursos|curso de Go" . 2>/dev/null | grep -v pytest_cache | grep -v "^Binary"
echo "--- fin ---"
echo
echo "=== 2. CLAUDE.md / raíz del proyecto ==="
grep -rniE "claude\.md|courses-ia-generated|repositorio de cursos" . 2>/dev/null | grep -v pytest_cache | grep -v "^Binary"
echo "--- fin ---"
