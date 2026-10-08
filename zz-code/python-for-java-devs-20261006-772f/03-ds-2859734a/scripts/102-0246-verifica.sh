# rescatado de la sesión 2859734a, 2026-09-14T02:46:03Z · Verify no external references remain
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ¿queda alguna cita a otro curso? ==="
grep -rniE "go-for-java|c-sharp|curso hermano|el curso de Go|curso de C#|cursos-|/Users/oskar/Developer" . 2>/dev/null | grep -v pytest_cache
echo "--- fin ---"
echo
echo "=== referencias genéricas que sobreviven (deben ser de género, no de proyecto) ==="
grep -rn "curso de Go\|otro curso\|curso de Angular" . 2>/dev/null | grep -v pytest_cache
echo
echo "=== rutas fuera de la carpeta del curso ==="
grep -rnE "\.\./\.\./\.\.|~/Developer|/Users/(?!marcela)" --include="*.md" . 2>/dev/null | grep -v pytest_cache | head
grep -rn "/Users/" . 2>/dev/null | grep -v pytest_cache | grep -v "marcela" | head
