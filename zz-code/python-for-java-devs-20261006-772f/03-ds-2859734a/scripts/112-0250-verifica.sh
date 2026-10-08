# rescatado de la sesión 2859734a, 2026-09-14T02:50:46Z · Check which offending lines are transcribed in the chapters
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ¿están transcritas en la prosa? ==="
for pat in "received.clear(); processed_keys.clear()" "_find_availability(agenda, branch" "from contextlib import contextmanager" "preguntas anotadas ({', '.join" "from answer import DraftAnswer, SYSTEM" "path.read_text(encoding=\"utf-8\") for path in sorted" "Omite el competidor 1" "from datetime import date" "pypdf devuelve vacío ante un escaneado" "zip(a, b))" "Requiere autorización previa" "zip(a, b) if x == y" "overrides: object"; do
  hits=$(grep -rl -- "$pat" ./*.md 2>/dev/null | tr '\n' ' ')
  printf "%-52s %s\n" "${pat:0:50}" "${hits:-—}"
done
