# rescatado de la sesión 2859734a, 2026-09-14T02:50:06Z · Check the structure document against the final state
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== 0-ESTRUCTURA: ¿describe el estado final de los complementos? ==="
sed -n '/Los \*\*complementos `ia` y `ds`\*\*/,+14p' 0-ESTRUCTURA-CURSO.md
echo
echo "=== ¿el README del curso y ESTRUCTURA se contradicen en conteos? ==="
grep -n "diecisiete\|17 secciones\|dieciocho fases\|18 fases" README.md 0-ESTRUCTURA-CURSO.md prompts/README.md | head
