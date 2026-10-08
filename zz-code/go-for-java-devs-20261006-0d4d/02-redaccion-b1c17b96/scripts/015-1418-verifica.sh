# rescatado de la sesión b1c17b96, 2026-09-12T14:18:30Z · Check unclosed code fences
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== BLOQUES DE CODIGO SIN CERRAR ==="
for f in *.md; do
  n=$(grep -c '^```' "$f")
  if [ $((n % 2)) -ne 0 ]; then echo "IMPAR $f: $n"; fi
done
echo "(vacio = ok)"
