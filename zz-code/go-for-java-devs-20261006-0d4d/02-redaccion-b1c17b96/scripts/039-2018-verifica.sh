# rescatado de la sesión b1c17b96, 2026-09-12T20:18:31Z · 
cd /Users/oskar/Developer/Learning/courses-ia-generated
cat >> .gitignore <<'EOF'

# ============================================================
# Material personal de búsqueda de empleo (NO publicar)
# Destino: repositorio privado de entrevistas. Mientras tanto,
# la raíz de este repo es zona de preparación. Ver REPASO-00-INDICE.md
# ============================================================

PLAN-REFRESCAMIENTO.md
REPASO-*.md
EOF
git status --short
echo "--- comprobación: ¿los ignora? ---"
git check-ignore -v PLAN-REFRESCAMIENTO.md REPASO-00-INDICE.md REPASO-04-BANCO-Y-HISTORIAS.md
