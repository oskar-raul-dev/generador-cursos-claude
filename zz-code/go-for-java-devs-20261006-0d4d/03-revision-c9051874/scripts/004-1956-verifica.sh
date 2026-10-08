# rescatado de la sesión c9051874, 2026-09-13T19:56:01Z · Audit external refs and rough exercise counts
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs
echo "=== 1. refs a otros cursos / proyecto raiz ==="
grep -rniE "cursos-algoritmos|cursos-[a-z]+/|propuestas-cursos|_oskar|courses-ia-generated|CLAUDE\.md|ruta-nosql|angular|python-for-java|c-sharp|docker-container|/Users/" . || echo "ninguna"
echo
echo "=== 2. conteo de ejercicios declarado por fase (§8) ==="
for f in 0[0-9]-*.md 1[0-7]-*.md; do
  n=$(grep -cE "^[0-9]+\. " "$f" 2>/dev/null)
  echo "$f  lineas-numeradas:$n"
done
