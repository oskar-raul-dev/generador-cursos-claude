# rescatado de la sesión 2859734a, 2026-09-13T19:44:26Z · Inspect moved history file and prompts README header
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== head historia ==="; sed -n 1,30p 00-historia-de-aurea.md
echo "=== refs internos historia ==="; grep -n "prompts/\|este documento\|Este documento" 00-historia-de-aurea.md | head -20
echo "=== head prompts/README ==="; sed -n 1,25p prompts/README.md
echo "=== prompts/README cuenta docs ==="; grep -n "doce\|trece\|catorce\|once\|documentos" prompts/README.md | head
