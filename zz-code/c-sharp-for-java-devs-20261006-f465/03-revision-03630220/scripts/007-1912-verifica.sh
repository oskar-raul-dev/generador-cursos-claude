# rescatado de la sesión 03630220, 2026-09-13T19:12:17Z · Final verification
echo "=== VERIFICACIÓN FINAL ==="
echo "-- referencias externas --"
grep -rnE "CLAUDE\.md|cursos-[a-z]|curso(s)? hermano|otros cursos del|python-for-java|ruta-nosql|propuestas-cursos|_oskar" . --include="*.md" || echo "   ✅ cero"
echo "-- enlaces --"
grep -ohE "\]\(([^)h][^)]*)\)" *.md prompts/*.md | sed -E 's/^\]\(//; s/\)$//' | sed 's/#.*//' | sort -u | while read -r l; do [ -z "$l" ] && continue; [ -e "$l" ] || [ -e "prompts/$l" ] || echo "   ❌ $l"; done; echo "   ✅ todos resuelven"
echo "-- rutas de src citadas en las fases --"
grep -rhoE "src[\\\\/][A-Za-z0-9._\\\\/-]+" *.md | tr '\\' '/' | sed 's#/$##' | sort -u | while read -r p; do case "$p" in *Bench.Cli*|*Cordillera.Domain*|*Cordillera.Ops*|*Sige.Desktop*|*Sige.Billing*|*modern/Sige.Forms*|*duelo*|*datos-generados*) continue;; esac; [ -e "$p" ] || echo "   ⚠️  no existe aún: $p"; done | sort -u | head -20
echo "-- estructura --"
ls [0-9]*.md | wc -l | xargs echo "   documentos numerados:"; echo "   ✅ 25 fases + convención de git"
