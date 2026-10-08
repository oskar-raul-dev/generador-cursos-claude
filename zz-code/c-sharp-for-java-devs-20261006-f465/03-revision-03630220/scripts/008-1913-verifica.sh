# rescatado de la sesión 03630220, 2026-09-13T19:13:05Z · Audit all debt git diff commands
echo "=== todos los git diff de deuda ==="; grep -rhoE "git diff fase-[0-9]+ fase-[0-9]+ -- [^\`\"]*" *.md | sed 's/ *$//' | sort -u
echo
echo "=== rutas citadas en comentarios de código (// src/... o <!-- src/...) ==="
grep -rhoE "(//|<!--) src/[A-Za-z0-9._/-]+\.(cs|csproj|xaml|config|props|json|sql|razor)" *.md | sed -E 's#^(//|<!--) ##' | sort -u | wc -l | xargs echo "  rutas distintas:"
