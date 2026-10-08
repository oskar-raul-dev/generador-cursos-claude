# rescatado de la sesión 2859734a, 2026-09-14T02:56:41Z · Final inventory of the course folder
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
find . \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".ruff_cache" \) -type d -prune -exec rm -rf {} + 2>/dev/null
rm -rf src/ds0*/data src/ds0*/modelos src/ds0*/salida src/ds0*/cuadernos 2>/dev/null
echo "=== inventario final del curso ==="
printf "  documentos publicados: %s\n" "$(ls *.md | wc -l | tr -d ' ')"
printf "  líneas de prosa publicada: %s\n" "$(cat *.md | wc -l | tr -d ' ')"
printf "  documentos de prompts/: %s\n" "$(ls prompts/*.md | wc -l | tr -d ' ')"
printf "  directorios de src/: %s\n" "$(ls -d src/*/ | wc -l | tr -d ' ')"
printf "  archivos .py: %s\n" "$(find src -name '*.py' | wc -l | tr -d ' ')"
printf "  configuración de la raíz: %s\n" "$(ls ruff.toml pytest.ini .gitignore 2>/dev/null | tr '\n' ' ')"
echo
echo "=== nada generado en el árbol ==="
find . \( -name "data" -o -name "modelos" -o -name "salida" -o -name "cuadernos" -o -name "__pycache__" -o -name "*.pkl" -o -name "*.onnx" -o -name "*.png" \) | head || true
echo "  (vacío = limpio)"
