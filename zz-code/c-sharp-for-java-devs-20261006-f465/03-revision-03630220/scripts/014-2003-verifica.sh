# rescatado de la sesión 03630220, 2026-09-13T20:03:52Z · Wide sweep for external references
echo "════ barrido amplio de referencias externas ════"
grep -rniE "otro curso|otros cursos|este repositorio|del repositorio|en el repositorio|curso de [A-Z]|cursos de |repositorio de cursos" . --include="*.md" \
 | grep -viE "SDK del repositorio|archivo del repositorio|raíz del repositorio|árbol del repositorio|subárbol del repositorio|fuera del repositorio|repositorio de (ejecuciones|dotnet)|en el repositorio si alguien|en el repositorio y en el historial|en el repositorio como prueba|se quedan en el repositorio|está en el repositorio" \
 | sed 's/\(.\{155\}\).*/\1/'
