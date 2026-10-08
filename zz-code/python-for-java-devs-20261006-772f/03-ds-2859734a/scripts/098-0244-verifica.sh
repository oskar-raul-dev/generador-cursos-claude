# rescatado de la sesión 2859734a, 2026-09-14T02:44:38Z · Grep for references to other courses and the root CLAUDE.md
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== 1. Otros cursos del proyecto ==="
grep -rniE "go-for-java-devs|c-sharp-for-java-devs|csharp|curso hermano|curso de C#|angular|docker-container|cursos-algoritmos|propuestas-cursos|_oskar|ruta-nosql|cursos-<|otro curso|los demás cursos" --include=*.md --include=*.py --include=*.toml . 2>/dev/null | grep -v pytest_cache
echo "--- (vacío = bien) ---"
echo
echo "=== 2. CLAUDE.md y la raíz del proyecto ==="
grep -rniE "CLAUDE\.md|courses-ia-generated|directorio raíz del proyecto|repositorio de cursos" --include=*.md --include=*.py --include=*.toml . 2>/dev/null | grep -v pytest_cache
echo "--- (vacío = bien) ---"
